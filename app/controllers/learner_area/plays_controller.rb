module LearnerArea
  # Plays a program lesson in the site player. Program lessons may be
  # unpublished in the public library, so the public play route can't serve them.
  class PlaysController < BaseController
    def show
      enrollment = current_enrollment
      item = enrollment.cohort.program.program_items.lesson.find(params[:program_item_id])
      progress = Programs::Progress.new(enrollment)
      raise ActiveRecord::RecordNotFound unless progress.available?(item) && item.lesson.has_any_audio?

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("audio-player", partial: "learner_area/plays/player",
                                                                  locals: { item: item, progress: progress, cohort: enrollment.cohort })
        end
        format.html { redirect_to learner_cohort_path(enrollment.cohort) }
      end
    end
  end
end
