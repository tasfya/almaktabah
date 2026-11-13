module Learners
  class RegistrationsController < Devise::RegistrationsController
    include LearnerSite
    before_action :permit_learner_fields, only: :create

    protected

    def build_resource(hash = {})
      super
      resource.domain = @domain
    end

    def after_sign_up_path_for(resource)
      stored = stored_location_for(resource)
      complete_pending_enrollment(resource) || stored || learner_dashboard_path
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
