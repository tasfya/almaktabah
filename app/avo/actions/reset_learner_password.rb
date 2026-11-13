class Avo::Actions::ResetLearnerPassword < Avo::BaseAction
  self.name = "تعيين كلمة مرور جديدة"
  self.visible = -> { view.show? }
  self.message = "يضع كلمة مرور جديدة للطالب. أعطه إياها بنفسك؛ لا يُرسل أي بريد."

  def fields
    field :password, as: :password, name: "كلمة المرور الجديدة", required: true
  end

  def handle(records:, fields:, **)
    learner = records.first
    return error("اختر طالبًا") if learner.nil?

    if learner.update(password: fields[:password].to_s, password_confirmation: fields[:password].to_s)
      succeed "عُيّنت كلمة المرور"
    else
      # The learner's error messages already name the field.
      error learner.errors.map(&:message).to_sentence
      keep_modal_open
    end
  end
end
