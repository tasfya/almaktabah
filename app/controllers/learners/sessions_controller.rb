module Learners
  class SessionsController < Devise::SessionsController
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to new_learner_session_path, alert: t("programs.learner_auth.rate_limited") }
  end
end
