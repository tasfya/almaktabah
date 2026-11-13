class ReminderMailer < ApplicationMailer
  include LearnerMailTenancy

  helper LearnerAreaHelper

  def daily(enrollment, digest)
    @enrollment = enrollment
    @digest = digest
    @cohort = enrollment.cohort
    @program = @cohort.program
    use_domain(enrollment.domain)
    @opt_out_url = reminder_opt_out_url(token: enrollment.generate_token_for(:reminders_off))

    headers["List-Unsubscribe"] = "<#{@opt_out_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    mail(to: enrollment.learner.email, from: @identity.from, subject: subject_line)
  end

  private

  def subject_line
    key = @digest.lessons.empty? ? "programs.reminders.exam_subject" : "programs.reminders.subject"
    I18n.t(key, program: @program.title, locale: :ar)
  end
end
