module LearnerArea
  class RemindersController < BaseController
    def update
      current_enrollment.update!(reminders_enabled: params[:reminders_enabled] == "1")
      redirect_to learner_account_path, notice: t("programs.account.reminders_saved")
    end
  end
end
