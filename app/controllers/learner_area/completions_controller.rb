module LearnerArea
  class CompletionsController < BaseController
    # A second tab, a stale page or a racing double tap may tick a lesson that
    # is already ticked: that counts as done, not as a refusal.
    def create
      change do |progress, item|
        progress.tick!(item) unless progress.ticked?(item)
      rescue Programs::Progress::NotAllowed
        raise unless current_enrollment.lesson_completions.exists?(program_item: item)
      end
    end

    # params[:id] is the program item, so the timeline can undo without
    # knowing the completion's id.
    def destroy
      change(item_id: params[:id], refused: "programs.cohort.untick_refused") { |progress, item| progress.untick!(item) }
    end

    private

    def change(item_id: params[:program_item_id], refused: "programs.cohort.tick_refused")
      enrollment = current_enrollment
      @item = enrollment.cohort.program.program_items.find_by(id: item_id)
      raise Programs::Progress::NotAllowed unless @item

      yield Programs::Progress.new(enrollment), @item
      respond_to do |format|
        format.turbo_stream do
          load_timeline(enrollment)
          render "learner_area/completions/update"
        end
        format.html { redirect_to learner_cohort_path(enrollment.cohort) }
      end
    rescue Programs::Progress::NotAllowed
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = t(refused)
          render turbo_stream: turbo_stream.replace("program_flash", partial: "programs/flash"), status: :unprocessable_content
        end
        format.html { redirect_to learner_cohort_path(enrollment.cohort), alert: t(refused) }
      end
    end
  end
end
