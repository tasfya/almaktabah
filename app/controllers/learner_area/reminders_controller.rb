module LearnerArea
  class RemindersController < BaseController
    def update
      current_enrollment.update!(reminders_enabled: params[:reminders_enabled] == "1")
      flash[:reminders_saved_for] = current_enrollment.cohort_id
      redirect_to learner_account_path(anchor: "reminders_cohort_#{current_enrollment.cohort_id}")
    end
  end
end
