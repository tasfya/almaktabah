module LearnerArea
  class CompletionsController < BaseController
    def create
      enrollment = current_enrollment
      @item = enrollment.cohort.program.program_items.find_by(id: params[:program_item_id])
      raise Programs::Progress::NotAllowed unless @item

      Programs::Progress.new(enrollment).tick!(@item)
      respond_to do |format|
        format.turbo_stream { load_timeline(enrollment) }
        format.html { redirect_to learner_cohort_path(enrollment.cohort) }
      end
    rescue Programs::Progress::NotAllowed
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = t("programs.cohort.tick_refused")
          render turbo_stream: turbo_stream.replace("program_flash", partial: "programs/flash"), status: :unprocessable_content
        end
        format.html { redirect_to learner_cohort_path(enrollment.cohort), alert: t("programs.cohort.tick_refused") }
      end
    end
  end
end
