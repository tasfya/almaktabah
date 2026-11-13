# Delivery settings for mail sent to learners. Applied to the learner mailer
# classes only, so staff mail (Devise::Mailer for User) keeps the app-wide
# Action Mailer settings.
module LearnerMail
  def self.configure!(*mailers)
    settings = {
      address: ENV.fetch("LEARNER_SMTP_ADDRESS"),
      port: Integer(ENV.fetch("LEARNER_SMTP_PORT", "587")),
      user_name: ENV.fetch("LEARNER_SMTP_USERNAME"),
      password: ENV.fetch("LEARNER_SMTP_PASSWORD"),
      authentication: :login,
      enable_starttls: true
    }
    mailers.each do |mailer|
      mailer.delivery_method = :smtp
      mailer.smtp_settings = settings
      mailer.raise_delivery_errors = true
    end
  end
end
