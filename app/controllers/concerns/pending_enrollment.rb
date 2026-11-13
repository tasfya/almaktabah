# A guest who taps "enroll" is sent to sign up (or sign in) first; the cohort
# they asked for is kept in the session and joined right after they sign in.
module PendingEnrollment
  extend ActiveSupport::Concern

  # Long enough to fill the form, short enough that a later unrelated
  # sign-in doesn't enroll the learner in something they forgot about.
  TTL = 1.hour

  included do
    helper_method :pending_enrollment_cohort
  end

  private

  def remember_pending_enrollment(cohort)
    session[:pending_enrollment] = { "cohort_id" => cohort.id, "at" => Time.current.to_i }
  end

  def pending_enrollment_cohort
    return @pending_enrollment_cohort if defined?(@pending_enrollment_cohort)

    pending = session[:pending_enrollment]
    @pending_enrollment_cohort =
      if pending.is_a?(Hash) && @domain && Time.zone.at(pending["at"].to_i) > TTL.ago
        Cohort.includes(:program).where(program_id: Program.for_domain_id(@domain.id).published.select(:id)).find_by(id: pending["cohort_id"])
      end
  end

  # Joins the remembered cohort and returns where to land, or nil when there
  # is nothing pending.
  def complete_pending_enrollment(learner)
    result, cohort = enroll_pending(learner)
    case result
    when :enrolled
      flash[:notice] = t("programs.enrollments.enrolled")
      learner_cohort_path(cohort)
    when :already
      learner_cohort_path(cohort)
    when :closed
      flash[:alert] = t("programs.enrollments.closed")
      program_path(cohort.program)
    end
  end

  # Enrolls without deciding where to land, e.g. for an account that must
  # confirm its email first: the enrollment is waiting once it signs in, even
  # from another browser.
  def enroll_pending(learner)
    cohort = pending_enrollment_cohort
    session.delete(:pending_enrollment)
    return unless cohort

    [ enroll_learner(learner, cohort), cohort ]
  end

  def enroll_learner(learner, cohort)
    return :already if learner.enrollments.exists?(cohort: cohort)
    return :closed unless cohort.enrollment_open?

    learner.enrollments.create!(cohort: cohort, domain: @domain)
    :enrolled
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    raise unless learner.enrollments.exists?(cohort: cohort)

    :already
  end
end
