# Learner account pages need a known site: learner mail is sent on its behalf,
# so a host without a Domain row (which Devise pages otherwise allow) is refused.
module LearnerSite
  extend ActiveSupport::Concern

  included do
    include TransientBreadcrumbs

    before_action { render_not_found if @domain.nil? }
    before_action :setup_learner_account_breadcrumbs
    rate_limit to: 10, within: 3.minutes, only: :create,
      with: -> { redirect_to url_for(action: :new), alert: t("programs.learner_auth.rate_limited") }
  end

  private

  def setup_learner_account_breadcrumbs
    reset_breadcrumbs
    breadcrumb_for(t("programs.learner_auth.breadcrumbs.#{controller_name}"))
  end
end
