module Learners
  class RegistrationsController < Devise::RegistrationsController
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_learner_registration_path, alert: t("programs.learner_auth.rate_limited") }
    before_action :permit_learner_fields, only: :create

    protected

    def build_resource(hash = {})
      super
      resource.domain = @domain
    end

    def after_sign_up_path_for(_resource)
      learner_dashboard_path
    end

    def after_inactive_sign_up_path_for(_resource)
      new_learner_session_path
    end

    private

    def permit_learner_fields
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name, :gender ])
    end
  end
end
