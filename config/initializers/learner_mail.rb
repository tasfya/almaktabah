Rails.application.config.to_prepare do
  if Rails.configuration.x.learner_mail_enabled && Rails.env.production?
    LearnerMail.configure!(Learners::Mailer)
  end
end
