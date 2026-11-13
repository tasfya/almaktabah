# Learner account pages need a known site: learner mail is sent on its behalf,
# so a host without a Domain row (which Devise pages otherwise allow) is refused.
module LearnerSite
  extend ActiveSupport::Concern

  included do
    before_action { render_not_found if @domain.nil? }
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to url_for(action: :new), alert: t("programs.learner_auth.rate_limited") }
  end
end
