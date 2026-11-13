# A learner mail is sent on behalf of one site: From and every link use it.
module LearnerMailTenancy
  extend ActiveSupport::Concern

  included do
    layout "learner_mailer"
  end

  def default_url_options
    return super unless @identity

    @url_options.presence || @identity.url_options
  end

  private

  def use_domain(domain, url_options: nil)
    @url_options = url_options
    @domain = domain
    @identity = Learners::MailIdentity.new(domain)
  end
end
