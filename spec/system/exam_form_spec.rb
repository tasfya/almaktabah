require "rails_helper"

# The exam form's browser-side behaviour: the local draft, the unanswered
# check before the single submit, and the countdown.
RSpec.describe "Exam form", type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:learner) { create(:learner, password: "secret123", password_confirmation: "secret123") }
  let(:program) { create(:program, published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.current - 3) }
  let!(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }
  let(:exam) { create(:exam, :with_questions, program: program) }
  let(:draft_key) { "exam-draft:#{enrollment.id}:#{exam.id}" }

  before do
    lesson = create(:program_item, :lesson, program: program, position: 1)
    create(:cohort_slot, cohort: cohort, program_item: lesson, available_on: cohort.starts_on)
    create(:lesson_completion, enrollment: enrollment, program_item: lesson)
    item = create(:program_item, :exam, program: program, position: 2, exam: exam)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.current,
                         opens_at: 1.day.ago, closes_at: 1.hour.from_now)

    visit new_learner_session_path
    fill_in "learner_email", with: learner.email
    fill_in "learner_password", with: "secret123"
    find("form#new_learner [type=submit]").click
    expect(page).to have_no_current_path(new_learner_session_path)
  end

  def first_question = exam.questions.order(:position).first

  it "keeps a draft across a reload, names the unanswered questions, and clears the draft once submitted" do
    visit learner_cohort_exam_path(cohort, exam)
    find("input[name='answers[#{first_question.id}]'][value='#{first_question.correct_choice.id}']").click
    expect(page).to have_text("عن 1 من 3")

    expect(page.evaluate_script("localStorage.getItem('#{draft_key}') !== null")).to be(true)
    page.refresh
    expect(page).to have_checked_field("answers[#{first_question.id}]", with: first_question.correct_choice.id.to_s)
    expect(page).to have_text("عن 1 من 3")
    expect(page).to have_text("الوقت المتبقي")

    message = dismiss_confirm { click_button "تسليم الإجابات" }
    expect(message).to include("(رقم 2، 3)")
    expect(page).to have_css("fieldset[data-unanswered]", count: 2)
    expect(ExamAttempt.count).to eq(0)

    accept_confirm { click_button "تسليم الإجابات" }
    expect(page).to have_text("نتيجتك 33٪")
    expect(page.evaluate_script("localStorage.getItem('#{draft_key}') === null")).to be(true)
    expect(ExamAttempt.last.attempt_answers.count).to eq(1)
  end
end
