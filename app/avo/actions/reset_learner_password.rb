class Avo::Actions::ResetLearnerPassword < Avo::BaseAction
  self.name = "Reset password"
  self.visible = -> { view.show? }
  self.message = "Sets a new password for the learner. Give it to them yourself; no email is sent."

  def fields
    field :password, as: :password
  end

  def handle(records:, fields:, **)
    learner = records.first
    if learner.update(password: fields[:password].to_s, password_confirmation: fields[:password].to_s)
      succeed "Password reset"
    else
      error learner.errors.full_messages.to_sentence
      keep_modal_open
    end
  end
end
