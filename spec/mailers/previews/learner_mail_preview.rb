# Preview at /rails/mailers/learner_mail. Needs LEARNER_MAIL_ENABLED=1 so the
# confirmation and password routes are drawn.
class LearnerMailPreview < ActionMailer::Preview
  def confirmation_instructions
    Learners::Mailer.confirmation_instructions(learner, "preview-token", domain_id: Domain.first&.id)
  end

  def reset_password_instructions
    Learners::Mailer.reset_password_instructions(learner, "preview-token", domain_id: Domain.first&.id)
  end

  private

  def learner
    Learner.first || Learner.new(email: "learner@example.com", full_name: "عبد الله بن محمد", gender: :male, domain: Domain.first)
  end
end
