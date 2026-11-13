module LearnerArea
  class BaseController < ApplicationController
    include TransientBreadcrumbs

    before_action :no_store
    before_action :authenticate_learner!
    before_action :setup_learner_breadcrumbs

    rescue_from ActiveRecord::RecordNotFound do
      if request.format.turbo_stream?
        head :not_found
      else
        render_record_not_found(t("programs.cohort.not_found"), learner_dashboard_path)
      end
    end

    private

    def setup_learner_breadcrumbs
      reset_breadcrumbs
      breadcrumb_for(t("programs.dashboard.title"), learner_dashboard_path)
    end

    # Enrollments in programs shown on this site.
    def domain_enrollments
      program_ids = Program.for_domain_id(@domain.id).select(:id)
      current_learner.enrollments.where(cohort_id: Cohort.where(program_id: program_ids).select(:id))
    end

    def current_enrollment
      @current_enrollment ||= domain_enrollments.includes(cohort: :program).find_by!(cohort_id: params[:learner_cohort_id] || params[:id])
    end

    def load_timeline(enrollment)
      @enrollment = enrollment
      @cohort = enrollment.cohort
      @progress = Programs::Progress.new(enrollment)
      @items = @progress.items
      ActiveRecord::Associations::Preloader.new(
        records: @items,
        associations: [ { lesson: [ { audio_attachment: :blob }, { final_audio_attachment: :blob } ] }, { book: { file_attachment: :blob } } ]
      ).call
      @scores = enrollment.exam_attempts.pluck(:exam_id, :score_percent).to_h
      @certificate = enrollment.certificate
    end
  end
end
