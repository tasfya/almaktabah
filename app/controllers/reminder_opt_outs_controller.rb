# The unsubscribe link in reminder mail. GET only shows a confirm button, so
# link scanners change nothing; POST turns reminders off and also serves RFC
# 8058 one-click unsubscribe from mail clients, which send no session or CSRF
# token. The signed token is the only credential.
class ReminderOptOutsController < ApplicationController
  skip_forgery_protection only: :create
  before_action :no_store
  before_action :set_enrollment

  def show
  end

  def create
    @enrollment.update!(reminders_enabled: false)
  end

  private

  # Unsubscribing must work from any browser or mail client, however old.
  def allow_browser(**)
  end

  def set_enrollment
    @enrollment = Enrollment.find_by_token_for(:reminders_off, params[:token])
    render_not_found unless @enrollment
  end
end
