class EnrollmentsController < ApplicationController
  def create
    program = Program.for_domain_id(@domain.id).published.friendly.find(params[:program_id])
    cohort = program.cohorts.find(params[:cohort_id])
    return send_guest_to_sign_up(cohort) unless learner_signed_in?

    case enroll_learner(current_learner, cohort)
    when :enrolled then redirect_to learner_cohort_path(cohort), notice: t("programs.enrollments.enrolled")
    when :already then redirect_to learner_cohort_path(cohort)
    when :closed then redirect_to program_path(program), alert: t("programs.enrollments.closed")
    end
  rescue ActiveRecord::RecordNotFound
    render_record_not_found(t("programs.not_found"), programs_path)
  end

  private

  def send_guest_to_sign_up(cohort)
    return redirect_to program_path(cohort.program), alert: t("programs.enrollments.closed") unless cohort.enrollment_open?

    remember_pending_enrollment(cohort)
    store_location_for(:learner, program_path(cohort.program))
    redirect_to new_learner_registration_path
  end
end
