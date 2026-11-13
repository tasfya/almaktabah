module Learners
  class RegistrationsController < Devise::RegistrationsController
    before_action :permit_learner_fields, only: :create

    protected

    def after_sign_up_path_for(_resource)
      learner_dashboard_path
    end

    private

    def permit_learner_fields
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name, :gender ])
    end
  end
end
