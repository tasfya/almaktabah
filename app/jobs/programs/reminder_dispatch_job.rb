module Programs
  # Runs hourly. Each cohort whose local time is in the morning window gets a
  # reminder job per enrollment not yet reminded today, so a missed tick is
  # caught up later in the morning but nothing goes out at night.
  class ReminderDispatchJob < ApplicationJob
    WINDOW = 6..11

    def perform
      return unless Rails.configuration.x.learner_mail_enabled

      now = Time.current
      Cohort.find_each do |cohort|
        next unless WINDOW.cover?(now.in_time_zone(cohort.time_zone).hour)

        local_date = cohort.today(now)
        due_enrollments(cohort, local_date).find_each do |enrollment|
          ReminderJob.perform_later(enrollment.id, local_date.iso8601)
        end
      end
    end

    private

    def due_enrollments(cohort, local_date)
      cohort.enrollments
        .where(reminders_enabled: true, completed_at: nil)
        .where(learner_id: Learner.where.not(confirmed_at: nil).select(:id))
        .where.not(id: ReminderDelivery.where(local_date: local_date).select(:enrollment_id))
    end
  end
end
