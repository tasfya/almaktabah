class EnrollmentsController < ApplicationController
  before_action :remember_program_for_guest
  before_action :authenticate_learner!

  def create
    program = Program.for_domain_id(@domain.id).published.friendly.find(params[:program_id])
    cohort = program.cohorts.find(params[:cohort_id])
    return redirect_to program_path(program), alert: t("programs.enrollments.closed") unless cohort.enrollment_open?

    enrollment = current_learner.enrollments.find_by(cohort: cohort)
    enrollment ||= current_learner.enrollments.create!(cohort: cohort, domain: @domain)
    redirect_to learner_cohort_path(cohort), notice: (t("programs.enrollments.enrolled") if enrollment.previously_new_record?)
  rescue ActiveRecord::RecordNotUnique
    redirect_to learner_cohort_path(cohort)
  rescue ActiveRecord::RecordNotFound
    render_record_not_found(t("programs.not_found"), programs_path)
  end

  private

  # Devise only remembers GET locations, so a guest who taps "enroll" is sent
  # back to the program page after signing in or up.
  def remember_program_for_guest
    store_location_for(:learner, program_path(params[:program_id])) unless learner_signed_in?
  end
end
