module Programs
  # Runs hourly. Each cohort whose local time is in the morning window gets a
  # reminder job per enrollment not yet reminded today, so a missed tick is
  # caught up later in the morning but nothing goes out at night.
  class ReminderDispatchJob < ApplicationJob
    WINDOW = 6..11

    def perform
      return unless Rails.configuration.x.learners_enabled && Rails.configuration.x.learner_mail_enabled

      now = Time.current
      Cohort.find_each do |cohort|
        next unless WINDOW.cover?(now.in_time_zone(cohort.time_zone).hour)

        local_date = cohort.today(now)
        next unless anything_to_say?(cohort, local_date, now)

        jobs = due_enrollments(cohort, local_date).pluck(:id).map { |id| ReminderJob.new(id, local_date.iso8601) }
        ActiveJob.perform_all_later(jobs)
      end
    end

    private

    # A cheap superset of ReminderDigest#empty? for the whole cohort, so days
    # with nothing to say (and cohorts not started or finished) enqueue nothing.
    def anything_to_say?(cohort, local_date, now)
      start_of_day = local_date.in_time_zone(cohort.time_zone)
      next_reminder = now + 24.hours
      slots = cohort.cohort_slots
      slots.where(available_on: local_date)
        .or(slots.where(opens_at: start_of_day...next_reminder))
        .or(slots.where(closes_at: now..next_reminder).where.not(closes_at: now))
        .exists?
    end

    def due_enrollments(cohort, local_date)
      cohort.enrollments
        .where(reminders_enabled: true, completed_at: nil)
        .where(learner_id: Learner.where.not(confirmed_at: nil).select(:id))
        .where.not(id: ReminderDelivery.where(local_date: local_date).select(:enrollment_id))
    end
  end
end
