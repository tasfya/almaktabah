class LectureKindAssignmentJob < ApplicationJob
  queue_as :default

  TEN_MINUTES = 600

  def perform
    Rails.logger.info "Starting lecture kind assignment..."

    # Find lectures with duration under 10 minutes that don't have a kind set
    updated = Lecture
      .where(kind: nil)
      .where.not(duration: nil)
      .where("duration > 0 AND duration < ?", TEN_MINUTES)
      .update_all(kind: :benefit)

    Rails.logger.info "Lecture kind assignment complete. Set #{updated} lectures to 'benefit'."
  end
end
