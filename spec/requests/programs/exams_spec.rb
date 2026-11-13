require "rails_helper"

RSpec.describe "Taking an exam", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  include_context "with tenant domain"

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:learner) { create(:learner) }
  let(:program) { create(:program, published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let!(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }
  let(:exam) { create(:exam, :with_questions, program: program, title: "اختبار القواعد الأربع") }
  let(:questions) { exam.questions.includes(:choices).to_a }
  let!(:lesson) { schedule(create(:program_item, :lesson, program: program, position: 1), on: Date.new(2025, 11, 8)) }
  let!(:exam_item) { schedule_exam(create(:program_item, :exam, program: program, position: 2, exam: exam)) }
  let(:during_window) { riyadh.local(2025, 11, 20, 12) }

  def schedule(item, on:)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: on)
    item
  end

  def schedule_exam(item)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 19),
                         opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
    item
  end

  def answers(correct_count)
    questions.each_with_index.to_h do |question, index|
      choice = index < correct_count ? question.correct_choice : question.choices.reject(&:correct?).first
      [ question.id.to_s, choice.id.to_s ]
    end
  end

  def submit(params)
    post submit_learner_cohort_exam_path(cohort, exam), params: { answers: params }
  end

  def tick_lesson
    create(:lesson_completion, enrollment: enrollment, program_item: lesson)
  end

  around { |example| travel_to(during_window) { example.run } }

  before { sign_in learner }

  it "shows the form while the exam is open, with the deadline in the cohort time zone" do
    tick_lesson

    get learner_cohort_exam_path(cohort, exam)

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.css("input[type=radio][name^='answers[']").size).to eq(9)
    expect(page.at_css("button[data-turbo-submits-with], input[type=submit][data-turbo-submits-with]")).to be_present
    expect(response.body).to include("21 نوفمبر 2025 22:00", questions.first.body)
  end

  it "keeps the form out of Turbo's page cache" do
    tick_lesson
    get learner_cohort_exam_path(cohort, exam)
    expect(response).to have_meta_tag("turbo-cache-control", "no-cache")
  end

  it "treats a malformed answers value as no answers" do
    tick_lesson
    post submit_learner_cohort_exam_path(cohort, exam), params: { answers: "foo" }
    expect(ExamAttempt.last.score_percent).to eq(0)
  end

  it "creates nothing when the learner opens the exam" do
    tick_lesson
    get learner_cohort_exam_path(cohort, exam)
    expect(ExamAttempt.count).to eq(0)
  end

  it "explains why the exam is not ready (unticked earlier lessons)" do
    get learner_cohort_exam_path(cohort, exam)

    expect(response.body).to include("أكمل سماع الدروس السابقة أولًا")
    expect(response.body).not_to include('name="answers[')
  end

  it "says when a locked exam opens" do
    travel_to riyadh.local(2025, 11, 18, 12)
    get learner_cohort_exam_path(cohort, exam)
    expect(response.body).to include("يُفتح في 19 نوفمبر 2025 00:00")
  end

  it "says the window was missed" do
    travel_to riyadh.local(2025, 11, 22)
    get learner_cohort_exam_path(cohort, exam)
    expect(response.body).to include("فات موعد الاختبار")
  end

  it "submits once and shows score and correct answers" do
    tick_lesson

    submit(answers(2))

    expect(response).to redirect_to(learner_cohort_exam_path(cohort, exam))
    follow_redirect!
    expect(response.body).to include("67٪", questions.last.correct_choice.body)
    expect(response.body).to include("ناجح")
    expect(ExamAttempt.last.score_percent).to eq(67)
  end

  it "marks a failing score" do
    tick_lesson
    submit(answers(1))
    follow_redirect!
    expect(response.body).to include("33٪", "لم تبلغ درجة النجاح")
  end

  it "a second submit shows the stored result, attempt count stays 1" do
    tick_lesson
    submit(answers(3))

    submit(answers(0))

    expect(response).to redirect_to(learner_cohort_exam_path(cohort, exam))
    expect(ExamAttempt.count).to eq(1)
    expect(ExamAttempt.last.score_percent).to eq(100)
    follow_redirect!
    expect(response.body).to include("نتيجتك 100٪")
  end

  it "accepts a submit at 21:59 Riyadh on the closing day" do
    tick_lesson
    travel_to riyadh.local(2025, 11, 21, 21, 59)

    submit(answers(3))

    expect(ExamAttempt.last.score_percent).to eq(100)
  end

  it "ignores a choice taken from another question of the same exam" do
    tick_lesson
    first, second, = questions

    submit({ first.id.to_s => second.correct_choice.id.to_s })

    expect(ExamAttempt.last).to have_attributes(score_percent: 0)
    expect(ExamAttempt.last.attempt_answers).to be_empty
  end

  it "refuses a submit after closing time" do
    tick_lesson
    travel_to riyadh.local(2025, 11, 21, 22)

    submit(answers(3))

    expect(response).to redirect_to(learner_cohort_exam_path(cohort, exam))
    expect(flash[:alert]).to eq("فات موعد الاختبار")
    expect(ExamAttempt.count).to eq(0)
  end

  it "ignores answers to questions of another exam" do
    tick_lesson
    other = create(:exam, :with_questions, program: program).questions.first

    submit(answers(3).merge(other.id.to_s => other.correct_choice.id.to_s))

    expect(ExamAttempt.last.attempt_answers.pluck(:question_id)).not_to include(other.id)
  end

  context "when the exam has no questions yet" do
    let(:exam) { create(:exam, program: program) }

    it "is not startable" do
      tick_lesson

      get learner_cohort_exam_path(cohort, exam)
      expect(response.body).to include("غير متاح بعد")
      expect(response.body).not_to include(submit_learner_cohort_exam_path(cohort, exam), "answers[")

      submit({})
      expect(ExamAttempt.count).to eq(0)
    end
  end

  it "sends no-store" do
    tick_lesson
    get learner_cohort_exam_path(cohort, exam)
    expect(response.headers["Cache-Control"]).to include("no-store")

    submit(answers(3))
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "returns not found for an exam this cohort doesn't schedule" do
    unscheduled = create(:exam, :with_questions, program: program)
    create(:program_item, :exam, program: program, position: 3, exam: unscheduled)

    get learner_cohort_exam_path(cohort, unscheduled)

    expect(response).to have_http_status(:not_found)
  end

  it "returns not found for a hidden exam" do
    exam_item.update!(hidden: true)
    get learner_cohort_exam_path(cohort, exam)
    expect(response).to have_http_status(:not_found)
  end

  it "returns not found for an exam of a program on another site" do
    program.update!(domains: [ other_domain ])

    get learner_cohort_exam_path(cohort, exam)
    expect(response).to have_http_status(:not_found)

    submit(answers(3))
    expect(response).to have_http_status(:not_found)
    expect(ExamAttempt.count).to eq(0)
  end

  it "returns not found for another learner's cohort" do
    other_cohort = create(:cohort, program: program)
    create(:enrollment, cohort: other_cohort, domain: domain)

    get learner_cohort_exam_path(other_cohort, exam)

    expect(response).to have_http_status(:not_found)
  end

  it "links the exam from the timeline" do
    get learner_cohort_path(cohort)
    expect(response.body).to include(learner_cohort_exam_path(cohort, exam))
  end
end
