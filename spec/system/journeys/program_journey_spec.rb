# frozen_string_literal: true

require "rails_helper"

# A visitor on a phone finds a program, signs up while enrolling, follows the
# timeline over the days, takes the exam, opens her certificate, and finally
# deletes her account, which revokes the certificate. Every step follows the
# links and buttons the pages render.
RSpec.describe "Journey: a learner completes a program", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:program) { create(:program, title: "الأصول الثلاثة", published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program, name: "دفعة الشتاء", starts_on: Date.new(2025, 11, 8)) }
  let(:exam) { create(:exam, :with_questions, program: program, title: "اختبار الأصول الثلاثة") }
  let(:lessons) do
    [ "الدرس الأول", "الدرس الثاني", "الدرس الثالث" ].each_with_index.map do |title, index|
      create(:program_item, :lesson, program: program, position: index + 1, title_override: title)
    end
  end

  before do
    travel_to riyadh.local(2025, 11, 8, 10)
    lessons.each_with_index do |item, index|
      create(:cohort_slot, cohort: cohort, program_item: item, available_on: cohort.starts_on + [ 0, 1, 1 ][index])
    end
    exam_item = create(:program_item, :exam, program: program, position: 4, exam: exam)
    create(:cohort_slot, cohort: cohort, program_item: exam_item, available_on: Date.new(2025, 11, 10),
                         opens_at: riyadh.local(2025, 11, 10), closes_at: riyadh.local(2025, 11, 12, 22))

    page.driver.with_playwright_page { |pw| pw.viewport_size = { width: 360, height: 800 } }
  end

  after { travel_back }

  def tick_button(title) = "button[aria-label='#{I18n.t("programs.cohort.tick_label", title: title)}']"

  def tick(title)
    find(tick_button(title)).click
    expect(page).to have_css("button[aria-label='#{I18n.t("programs.cohort.untick_label", title: title)}']")
  end

  def answer(question, correct:)
    choice = correct ? question.correct_choice : question.choices.reject(&:correct?).first
    find("input[name='answers[#{question.id}]'][value='#{choice.id}']").click
  end

  it "signs up, studies, passes the exam, opens the certificate and deletes the account" do
    visit programs_path
    click_link "الأصول الثلاثة"
    expect(page).to have_text("دفعة الشتاء")

    click_button I18n.t("programs.show.enroll_guest")
    fill_in I18n.t("programs.learner_auth.full_name"), with: "عائشة المتعلمة"
    find("label", text: I18n.t("programs.learner_auth.female")).click
    fill_in I18n.t("auth.email"), with: "aisha@example.com"
    fill_in I18n.t("auth.password"), with: "secret123"
    fill_in I18n.t("auth.password_confirmation"), with: "secret123"
    click_button I18n.t("programs.learner_auth.sign_up")

    expect(page).to have_text(I18n.t("programs.enrollments.enrolled"))
    expect(page).to have_css("h1", text: "الأصول الثلاثة")
    tick("الدرس الأول")
    expect(page).to have_no_css(tick_button("الدرس الثاني"))

    travel_to riyadh.local(2025, 11, 10, 12)
    visit current_path
    tick("الدرس الثاني")
    tick("الدرس الثالث")

    click_link "اختبار الأصول الثلاثة"
    expect(page).to have_text("3 أسئلة · محاولة واحدة")
    first, second, third = exam.questions.includes(:choices).order(:position).to_a
    answer(first, correct: true)
    answer(second, correct: true)
    answer(third, correct: false)
    accept_confirm { click_button I18n.t("programs.exam.submit") }

    expect(page).to have_text("نتيجتك 66٪")
    expect(page).to have_text(I18n.t("programs.exam.passed_female"))

    click_link I18n.t("programs.exam.back")
    certificate = Certificate.last
    expect(page).to have_text(I18n.t("programs.cohort.certificate_issued", number: certificate.number))
    click_link I18n.t("programs.cohort.open_certificate")

    expect(page).to have_text(I18n.t("programs.certificate.valid"))
    expect(page).to have_text(I18n.t("programs.certificate.body.female.student"))
    expect(page).to have_text(I18n.t("programs.certificate.body.female.completed"))
    expect(page).to have_text("عائشة المتعلمة")
    certificate_page = current_path

    click_link I18n.t("navigation.my_programs"), match: :first
    click_link I18n.t("programs.account.link")
    fill_in I18n.t("programs.account.current_password"), with: "secret123"
    accept_confirm { click_button I18n.t("programs.account.delete") }
    expect(page).to have_text(I18n.t("programs.account.deleted"))
    expect(Learner.count).to eq(0)

    visit certificate_page
    expect(page).to have_text(I18n.t("programs.certificate.revoked_title"))
    expect(page).to have_no_text(I18n.t("programs.certificate.valid"))
  end
end
