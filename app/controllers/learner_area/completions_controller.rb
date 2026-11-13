module LearnerArea
  class CompletionsController < BaseController
    def create
      enrollment = current_enrollment
      @item = enrollment.cohort.program.program_items.find_by(id: params[:program_item_id])
      return refuse(enrollment) unless @item && tick(enrollment)

      respond_to do |format|
        format.turbo_stream { load_timeline(enrollment) }
        format.html { redirect_to learner_cohort_path(enrollment.cohort) }
      end
    end

    private

    # A second tab, a stale page or a racing double tap may tick a lesson that
    # is already ticked: that counts as done, not as a refusal.
    def tick(enrollment)
      progress = Programs::Progress.new(enrollment)
      progress.tick!(@item) unless progress.ticked?(@item)
      true
    rescue Programs::Progress::NotAllowed
      enrollment.lesson_completions.exists?(program_item: @item)
    end

    def refuse(enrollment)
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
