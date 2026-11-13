module Learners
  # The sender and link host of a mail sent to a learner on behalf of one site.
  # Subdomain sites (fawzan.3ilm.org) send from their parent zone; a zone not
  # verified at the mail provider (LEARNER_MAIL_DOMAINS) borrows the first
  # verified one, while links still point at the learner's own site.
  class MailIdentity
    attr_reader :domain

    def initialize(domain)
      @domain = domain
    end

    def host
      domain.host
    end

    def from
      ActionMailer::Base.email_address_with_name("no-reply@#{sending_zone}", domain.title.presence || domain.host)
    end

    def url_options
      defaults = Rails.application.config.action_mailer.default_url_options.to_h.except(:host)
      defaults.merge(host: host, protocol: Rails.env.development? ? "http" : "https")
    end

    private

    def sending_zone
      zone = host.split(".").last(2).join(".")
      verified = ENV.fetch("LEARNER_MAIL_DOMAINS", "").split(",").map(&:strip).compact_blank
      verified.include?(zone) || verified.empty? ? zone : verified.first
    end
  end
end
