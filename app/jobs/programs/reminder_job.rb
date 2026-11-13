module Programs
  # Sends one enrollment's reminder for one cohort-local day, at most once.
  # There is no retry_on: the next hourly dispatch inside the morning window
  # is the retry.
  #
  # When the mail server refuses us (bad credentials, unreachable), every job
  # of that tick would fail the same way and pile up as failed jobs. The first
  # failure pauses sending until the next tick instead, so a broken setup
  # costs one failed job per hour.
  class ReminderJob < ApplicationJob
    SMTP_DOWN_KEY = "programs/reminders/smtp_down".freeze
    SMTP_DOWN_FOR = 50.minutes

    # Failures where the server cannot have accepted the mail, so the day's
    # claim is released and a later tick may send it.
    NOT_SENT = [
      Net::OpenTimeout, Errno::ECONNREFUSED, SocketError,
      Net::SMTPServerBusy, Net::SMTPAuthenticationError
    ].freeze

    def perform(enrollment_id, local_date)
      return unless Rails.configuration.x.learners_enabled && Rails.configuration.x.learner_mail_enabled

      enrollment = Enrollment.find_by(id: enrollment_id)
      return unless enrollment&.reminders_enabled? && enrollment.completed_at.nil? && enrollment.learner.confirmed?
      return unless enrollment.cohort.today.iso8601 == local_date
      return unless ReminderDispatchJob::WINDOW.cover?(Time.current.in_time_zone(enrollment.cohort.time_zone).hour)

      digest = ReminderDigest.new(enrollment)
      return if digest.empty?
      return if Rails.cache.read(SMTP_DOWN_KEY)

      deliver(enrollment, digest, local_date)
    end

    private

    def deliver(enrollment, digest, local_date)
      delivery = claim(enrollment, local_date) or return
      begin
        ReminderMailer.daily(enrollment, digest).deliver_now
      rescue *NOT_SENT
        delivery.destroy!
        Rails.cache.write(SMTP_DOWN_KEY, true, expires_in: SMTP_DOWN_FOR)
        raise
      end
      # Any other error keeps the claim: the mail may have been accepted, and
      # a second copy is worse than a missed one.
      delivery.update!(sent_at: Time.current)
    end

    def claim(enrollment, local_date)
      enrollment.reminder_deliveries.create!(local_date: local_date)
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
