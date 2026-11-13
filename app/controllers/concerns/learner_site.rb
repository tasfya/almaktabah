# Learner account pages need a known site: learner mail is sent on its behalf,
# so a host without a Domain row (which Devise pages otherwise allow) is refused.
#
# Account forms are throttled per email, against guessing one account's
# password, and more loosely per address, since many learners share one public
# address (a masjid's Wi-Fi, a mobile carrier's NAT).
module LearnerSite
  extend ActiveSupport::Concern

  included do
    include TransientBreadcrumbs

    before_action { render_not_found if @domain.nil? }
    before_action :setup_learner_account_breadcrumbs
    rate_limit to: 10, within: 3.minutes, only: :create, name: "email", by: :learner_email_rate_key, with: :refuse_rate_limited
    rate_limit to: 60, within: 3.minutes, only: :create, name: "address", by: :learner_address_rate_key, with: :refuse_rate_limited
  end

  private

  def setup_learner_account_breadcrumbs
    reset_breadcrumbs
    breadcrumb_for(t("programs.learner_auth.breadcrumbs.#{controller_name}"))
  end

  def learner_email_rate_key
    learner = params[:learner]
    email = learner[:email] if learner.is_a?(ActionController::Parameters)
    email.to_s.strip.downcase.presence || request.remote_ip
  end

  # One IPv6 subscriber usually holds a whole /64, so count the /64.
  def learner_address_rate_key
    address = IPAddr.new(request.remote_ip)
    address.ipv6? ? address.mask(64).to_s : address.to_s
  rescue IPAddr::Error
    request.remote_ip
  end

  def refuse_rate_limited
    redirect_to url_for(action: :new), alert: t("programs.learner_auth.rate_limited")
  end
end
