# A learner mail is sent on behalf of one site: From and every link use it.
module LearnerMailTenancy
  extend ActiveSupport::Concern

  included do
    layout "learner_mailer"
  end

  def default_url_options
    @identity ? @identity.url_options : super
  end

  private

  def use_domain(domain)
    @domain = domain
    @identity = Learners::MailIdentity.new(domain)
  end
end
