# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Avo admin for programs", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  include_context "with tenant domain"

  # The cohort starts on 2025-11-08; generating its schedule later would put
  # every exam window in the past, which Generate refuses.
  before { travel_to Time.zone.local(2025, 11, 1, 12) }

  let(:admin) { create(:user, admin: true) }
  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let!(:lesson_items) { create_list(:program_item, 3, :lesson, program: program) }
  let!(:exam_item) { create(:program_item, :exam, program: program, exam: create(:exam, :with_questions, program: program)) }

  before { sign_in admin }

  def run_action(resource_name, action, records, **fields)
    post "/avo/resources/#{resource_name}/actions?action_id=#{action}",
         params: { fields: { avo_resource_ids: Array(records).map(&:to_param).join(",") }.merge(fields) },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:ok)
  end

  # The params a browser would submit for the record form in the page: enabled
  # fields only, checked boxes only, the selected option of each select.
  def submitted_form_params(html, scope)
    form = Nokogiri::HTML(html).css("form").find { |f| f.at_css("[name^='#{scope}[']") }
    form.css("input, select, textarea").each_with_object([]) do |input, pairs|
      name = input["name"]
      next if name.blank? || !name.start_with?("#{scope}[") || input.has_attribute?("disabled")
      next if input["type"] == "checkbox" && !input.has_attribute?("checked")

      value = case input.name
      when "select" then input.at_css("option[selected]")&.[]("value").to_s
      when "textarea" then input.text
      else input["value"].to_s
      end
      pairs << [ name, value ]
    end
  end

  def generate(**fields)
    run_action("cohorts", Avo::Actions::GenerateCohortSchedule, cohort,
               weekdays: [ "", "0", "1", "2", "3", "4", "6" ], lessons_per_day: "1",
               exam_open_wday: "3", exam_close_wday: "5", exam_close_hour: "22", skip_ranges: "", **fields)
  end

  describe "pages" do
    let(:learner) { create(:learner) }
    let(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }
    let!(:certificate) { create(:certificate, enrollment: enrollment) }

    before do
      generate
      create(:lesson_completion, enrollment: enrollment, program_item: lesson_items.first)
    end

    %w[programs program_items exams questions cohorts cohort_slots learners enrollments certificates].each do |resource|
      it "lists #{resource}" do
        get "/avo/resources/#{resource}"

        expect(response).to have_http_status(:ok)
      end
    end

    it "shows each record and the forms of the editable ones" do
      question = exam_item.exam.questions.first
      [
        "/avo/resources/programs/#{program.to_param}", "/avo/resources/programs/#{program.to_param}/edit",
        "/avo/resources/programs/new",
        "/avo/resources/program_items/#{exam_item.id}", "/avo/resources/program_items/#{exam_item.id}/edit",
        "/avo/resources/program_items/new?via_relation=program&via_relation_class=Program&via_record_id=#{program.to_param}",
        "/avo/resources/exams/#{exam_item.exam_id}",
        "/avo/resources/questions/#{question.id}", "/avo/resources/questions/#{question.id}/edit",
        "/avo/resources/questions/new?via_relation=exam&via_relation_class=Exam&via_record_id=#{exam_item.exam_id}",
        "/avo/resources/cohorts/#{cohort.id}", "/avo/resources/cohorts/#{cohort.id}/edit",
        "/avo/resources/cohort_slots/#{cohort.cohort_slots.first.id}/edit",
        "/avo/resources/learners/#{learner.id}",
        "/avo/resources/enrollments/#{enrollment.id}",
        "/avo/resources/certificates/#{certificate.number}"
      ].each do |path|
        get path

        expect(response).to have_http_status(:ok), "#{path} → #{response.status}"
      end
    end

    it "shows an enrollment's progress" do
      get "/avo/resources/enrollments/#{enrollment.id}"

      expect(response.body).to include("#{Programs::Progress.new(enrollment).percent_complete}%")
    end

    it "prefills the next position for a new item of a program" do
      get "/avo/resources/program_items/new?via_relation=program&via_relation_class=Program&via_record_id=#{program.to_param}"

      expect(response.body).to match(/<input value="#{program.program_items.maximum(:position) + 1}"[^>]*name="program_item\[position\]"/)
    end
  end

  it "turns a signed-in non-admin back to the home page" do
    sign_out admin
    sign_in create(:user)

    get "/avo/resources/programs"

    expect(response).to redirect_to("http://localhost/")
  end

  describe "program sites" do
    it "assigns the checked sites on create" do
      post "/avo/resources/programs", params: { program: { title: "برنامج", pass_mark: "60", sites: [ "", other_domain.id.to_s ] } }

      expect(Program.find_by!(title: "برنامج").domains).to contain_exactly(other_domain)
    end

    it "shows the assigned sites as checked boxes on the edit form" do
      program.assign_to(other_domain)

      get "/avo/resources/programs/#{program.to_param}/edit"

      expect(response.body).to match(/id="program_sites_#{other_domain.id}"[^>]*checked="checked"/)
      expect(response.body).to match(/id="program_sites_#{domain.id}"(?![^>]*checked)[^>]*>/)
    end

    it "removes the unchecked sites on update" do
      program.assign_to(domain)
      program.assign_to(other_domain)

      patch "/avo/resources/programs/#{program.to_param}", params: { program: { title: program.title, sites: [ "", domain.id.to_s ] } }

      expect(program.reload.domains).to contain_exactly(domain)
    end

    it "keeps the sites when the update fails validation" do
      program.assign_to(domain)

      patch "/avo/resources/programs/#{program.to_param}", params: { program: { title: "", sites: [ "", other_domain.id.to_s ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(program.reload.domains).to contain_exactly(domain)
    end

    it "leaves the sites alone when the form does not send them" do
      program.assign_to(other_domain)

      patch "/avo/resources/programs/#{program.to_param}", params: { program: { title: "عنوان جديد" } }

      expect(program.reload).to have_attributes(title: "عنوان جديد", domains: [ other_domain ])
    end

    it "shows the model's error instead of failing when the program has enrollments" do
      create(:enrollment, cohort: cohort, domain: domain)

      delete "/avo/resources/programs/#{program.to_param}", headers: turbo

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("طلاب مسجلون في دفعات هذا البرنامج")
      expect(response.body).not_to include("Failed to destroy")
      expect(Program.exists?(program.id)).to be(true)
    end

    it "shows the model's error when an exam has attempts" do
      exam = exam_item.exam
      create(:exam_attempt, exam: exam, enrollment: create(:enrollment, cohort: cohort, domain: domain))

      delete "/avo/resources/exams/#{exam.id}", headers: turbo

      expect(response.body).to include("طلاب أجابوا عن هذا الاختبار")
      expect(Exam.exists?(exam.id)).to be(true)
    end

    it "refuses to delete a cohort with enrollments without failing" do
      create(:enrollment, cohort: cohort, domain: domain)

      delete "/avo/resources/cohorts/#{cohort.id}", headers: turbo

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("طلاب مسجلون في هذه الدفعة")
      expect(response.body).not_to include("Failed to destroy")
      expect(Cohort.exists?(cohort.id)).to be(true)
    end
  end

  describe "program items" do
    it "saves back exactly what the edit form shows, references included" do
      item = lesson_items.last
      book_item = create(:program_item, :book, program: program)

      [ item, book_item ].each do |record|
        get "/avo/resources/program_items/#{record.id}/edit"
        pairs = submitted_form_params(response.body, "program_item").map { |name, value| name == "program_item[hidden]" ? [ name, "1" ] : [ name, value ] }

        patch "/avo/resources/program_items/#{record.id}", params: URI.encode_www_form(pairs),
              headers: { "Content-Type" => "application/x-www-form-urlencoded" }

        expect(response).to have_http_status(:redirect)
        expect(record.reload).to have_attributes(hidden: true, lesson_id: record.lesson_id, book_id: record.book_id, program_id: program.id)
      end
    end

    it "takes the lesson by id" do
      lesson = create(:lesson)

      post "/avo/resources/program_items", params: { program_item: { program_id: program.id, position: "9999", kind: "lesson", lesson_id: lesson.id.to_s } }

      expect(program.program_items.find_by!(position: 9999).lesson).to eq(lesson)
    end

    it "keeps the hidden flag editable" do
      item = lesson_items.first

      patch "/avo/resources/program_items/#{item.id}", params: { program_item: { hidden: "1" } }

      expect(item.reload.hidden).to be(true)
    end
  end

  describe "questions and their choices" do
    let(:exam) { exam_item.exam }

    def question_params(**attributes)
      { exam_id: exam.id, position: "9", kind: "single_choice", body: "سؤال؟",
        choice_1: "أ", choice_2: "ب", choice_3: "ج", choice_4: "", choice_5: "", correct_slot: "2" }.merge(attributes)
    end

    it "shows the choices in the edit form" do
      question = exam.questions.first

      get "/avo/resources/questions/#{question.id}/edit"

      question.choices.each_with_index do |choice, index|
        expect(response.body).to match(/value="#{Regexp.escape(ERB::Util.h(choice.body))}"[^>]*name="question\[choice_#{index + 1}\]"/)
      end
      expect(response.body).to match(/name="question\[correct_slot\]".*?<option selected="selected" value="1">/m)
    end

    it "creates a question with its choices and one correct answer" do
      post "/avo/resources/questions", params: { question: question_params }

      question = exam.questions.find_by!(position: 9)
      expect(question.choices.map { |c| [ c.body, c.correct ] }).to eq([ [ "أ", false ], [ "ب", true ], [ "ج", false ] ])
    end

    it "fills true/false choices when left blank" do
      post "/avo/resources/questions", params: { question: question_params(kind: "true_false", choice_1: "", choice_2: "", choice_3: "", correct_slot: "1") }

      expect(exam.questions.find_by!(position: 9).choices.map { |c| [ c.body, c.correct ] }).to eq([ [ "صح", true ], [ "خطأ", false ] ])
    end

    it "switches the correct answer and removes a blanked choice in one save" do
      question = exam.questions.first
      bodies = question.choices.map(&:body)

      patch "/avo/resources/questions/#{question.id}",
            params: { question: question_params(position: question.position.to_s, choice_1: bodies[0], choice_2: "", choice_3: bodies[2], correct_slot: "3") }

      expect(question.reload.choices.map { |c| [ c.body, c.correct ] }).to eq([ [ bodies[0], false ], [ bodies[2], true ] ])
    end

    it "refuses a question without a correct answer" do
      post "/avo/resources/questions", params: { question: question_params(correct_slot: "") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("activerecord.errors.messages.exactly_one_correct", locale: :ar))
      expect(exam.questions.where(position: 9)).to be_empty
    end

    it "refuses a true/false question with three choices" do
      post "/avo/resources/questions", params: { question: question_params(kind: "true_false", correct_slot: "1") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(exam.questions.where(position: 9)).to be_empty
    end

    it "refuses to remove a choice that a learner answered, without failing" do
      question = exam.questions.first
      answered = question.choices.last
      attempt = create(:exam_attempt, exam: exam, enrollment: create(:enrollment, cohort: cohort, domain: domain))
      AttemptAnswer.create!(exam_attempt: attempt, question: question, choice: answered)

      patch "/avo/resources/questions/#{question.id}",
            params: { question: question_params(position: question.position.to_s, choice_1: question.choices[0].body, choice_2: question.choices[1].body, choice_3: "", correct_slot: "1") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("طلاب اختاروا هذا الجواب")
      expect(Choice.exists?(answered.id)).to be(true)
    end

    it "refuses to delete an answered question with the model's message" do
      question = exam.questions.first
      attempt = create(:exam_attempt, exam: exam, enrollment: create(:enrollment, cohort: cohort, domain: domain))
      AttemptAnswer.create!(exam_attempt: attempt, question: question, choice: question.choices.first)

      delete "/avo/resources/questions/#{question.id}", headers: turbo

      expect(response.body).to include("طلاب أجابوا عن هذا السؤال")
      expect(response.body).not_to include("Failed to destroy")
      expect(Question.exists?(question.id)).to be(true)
    end
  end

  describe "panels of related records" do
    let(:other_program) { create(:program) }

    it "offers no existing record to attach" do
      get "/avo/resources/programs/#{program.to_param}/cohorts/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to match(/<option value="\d+"/)
    end

    it "refuses to attach or detach enrollments of a learner" do
      learner = create(:learner)
      enrollment = create(:enrollment, cohort: cohort, domain: domain)
      own = create(:enrollment, learner: learner, cohort: create(:cohort, program: program), domain: domain)

      post "/avo/resources/learners/#{learner.id}/enrollments", params: { fields: { related_id: enrollment.id } }
      delete "/avo/resources/learners/#{learner.id}/enrollments/#{own.id}"
      delete "/avo/resources/cohorts/#{cohort.id}/enrollments/#{enrollment.id}"

      expect(enrollment.reload.learner).not_to eq(learner)
      expect(Enrollment.exists?(own.id)).to be(true)
      expect(Enrollment.exists?(enrollment.id)).to be(true)
    end

    it "never moves a cohort, an item or a question to another parent" do
      other_exam = create(:exam, program: other_program)
      question = exam_item.exam.questions.first

      post "/avo/resources/programs/#{other_program.to_param}/cohorts", params: { fields: { related_id: cohort.id } }
      patch "/avo/resources/cohorts/#{cohort.id}", params: { cohort: { program_id: other_program.id, name: cohort.name } }
      patch "/avo/resources/program_items/#{lesson_items.first.id}", params: { program_item: { program_id: other_program.id } }
      patch "/avo/resources/questions/#{question.id}", params: { question: { exam_id: other_exam.id } }

      expect(cohort.reload.program).to eq(program)
      expect(lesson_items.first.reload.program).to eq(program)
      expect(question.reload.exam).to eq(exam_item.exam)
    end

    it "shows the parent of a saved record as read-only on its form" do
      get "/avo/resources/cohorts/#{cohort.id}/edit"

      expect(response.body).to match(/<select[^>]*disabled[^>]*name="cohort\[program_id\]"|<select[^>]*name="cohort\[program_id\]"[^>]*disabled/)
    end
  end

  describe "Generate schedule" do
    it "fills a slot for every item" do
      generate

      expect(cohort.cohort_slots.count).to eq(program.program_items.count)
      exam_slot = cohort.cohort_slots.find_by!(program_item: exam_item)
      expect(exam_slot.closes_at.in_time_zone("Asia/Riyadh").hour).to eq(22)
    end

    it "honours the breaks" do
      generate(skip_ranges: "2025-11-08..2025-11-10\n")

      expect(cohort.cohort_slots.minimum(:available_on)).to eq(Date.new(2025, 11, 11))
    end

    it "reads breaks typed with Arabic-Indic or Persian digits" do
      generate(skip_ranges: "٢٠٢٥-١١-٠٨..۲۰۲۵-۱۱-۱۰\n")

      expect(cohort.cohort_slots.minimum(:available_on)).to eq(Date.new(2025, 11, 11))
    end

    {
      "no weekday" => { weekdays: [ "" ] },
      "a bad break" => { skip_ranges: "2025-11-08..soon" },
      "a break without an end" => { skip_ranges: "2025-11-08" },
      "a reversed break" => { skip_ranges: "2025-11-20..2025-11-10" },
      "an hour out of range" => { exam_close_hour: "25" },
      "a blank number" => { lessons_per_day: "" }
    }.each do |label, fields|
      it "shows an error for #{label} and keeps the slots" do
        generate
        before = cohort.cohort_slots.pluck(:id)

        generate(**fields)

        expect(response.body).to include("bg-red-400")
        expect(cohort.cohort_slots.pluck(:id)).to eq(before)
      end
    end
  end

  describe "Generate schedule guards" do
    let(:other) { create(:cohort, program: program, name: "Other cohort", starts_on: Date.new(2025, 11, 8)) }

    def generate_on(cohorts)
      run_action("cohorts", Avo::Actions::GenerateCohortSchedule, cohorts,
                 weekdays: [ "", "0", "1", "2", "3", "4", "6" ], lessons_per_day: "1",
                 exam_open_wday: "3", exam_close_wday: "5", exam_close_hour: "22", skip_ranges: "")
    end

    def slot_rows(*cohorts)
      CohortSlot.where(cohort: cohorts).order(:id).pluck(:id, :available_on)
    end

    before do
      generate
      Programs::ScheduleGenerator.new(other, weekdays: [ 1 ]).call
    end

    it "refuses every selected cohort once one has a ticked lesson" do
      enrollment = create(:enrollment, cohort: cohort, domain: domain)
      create(:lesson_completion, enrollment: enrollment, program_item: lesson_items.first)
      before = slot_rows(cohort, other)

      generate_on([ other, cohort ])

      expect(response.body).to include("bg-red-400")
      expect(response.body).to include(cohort.name)
      expect(slot_rows(cohort, other)).to eq(before)
    end

    it "refuses once a learner has taken an exam" do
      create(:exam_attempt, exam: exam_item.exam, enrollment: create(:enrollment, cohort: cohort, domain: domain))
      before = slot_rows(cohort)

      generate_on(cohort)

      expect(response.body).to include("bg-red-400")
      expect(slot_rows(cohort)).to eq(before)
    end

    it "refuses every selected cohort when one would get an exam window that is already closed" do
      other.update!(starts_on: Date.new(2025, 10, 1))
      before = slot_rows(cohort, other)

      generate_on([ cohort, other ])

      expect(response.body).to include("bg-red-400")
      expect(response.body).to include("Other cohort")
      expect(slot_rows(cohort, other)).to eq(before)
    end

    it "regenerates cohorts with enrolled learners who have not started" do
      create(:enrollment, cohort: cohort, domain: domain)

      generate_on(cohort)

      expect(response.body).not_to include("bg-red-400")
    end
  end

  describe "Clear schedule" do
    before { generate }

    it "deletes the slots of a cohort without learner progress" do
      run_action("cohorts", Avo::Actions::ClearCohortSchedule, cohort)

      expect(cohort.cohort_slots.count).to eq(0)
    end

    it "refuses once a learner has progress and keeps the slots" do
      enrollment = create(:enrollment, cohort: cohort, domain: domain)
      create(:lesson_completion, enrollment: enrollment, program_item: lesson_items.first)

      run_action("cohorts", Avo::Actions::ClearCohortSchedule, cohort)

      expect(response.body).to include("bg-red-400")
      expect(cohort.cohort_slots.count).to eq(program.program_items.count)
    end
  end

  it "warns on a cohort that schedules an exam with no questions" do
    generate
    empty = create(:exam, program: program, title: "Unwritten exam")
    create(:cohort_slot, :exam, cohort: cohort, program_item: create(:program_item, :exam, program: program, exam: empty))

    get "/avo/resources/cohorts/#{cohort.id}"
    expect(response.body).to include("«Unwritten exam»")
    expect(response.body).to include("لا يحصل أي طالب في هذه الدفعة على شهادة")
    get "/avo/resources/cohorts"
    expect(response.body).to include("اختبار بلا أسئلة")
    get "/avo/resources/exams/#{empty.id}"
    expect(response.body).to include("هذا الاختبار بلا أسئلة")
    get "/avo/resources/exams"
    expect(response.body).to include("بلا أسئلة")
  end

  it "shows no warning when every scheduled exam has questions" do
    generate

    get "/avo/resources/cohorts/#{cohort.id}"
    expect(response.body).not_to include("بلا أسئلة")
    get "/avo/resources/exams/#{exam_item.exam_id}"
    expect(response.body).not_to include("بلا أسئلة")
  end

  it "names the program and cohort of each certificate on the index" do
    create(:certificate, enrollment: create(:enrollment, cohort: cohort, domain: domain))

    get "/avo/resources/certificates"

    expect(response.body).to include(program.title, cohort.name)
  end

  describe "Shift schedule" do
    before { generate }

    it "moves the slots on or after the date" do
      first, *rest = cohort.cohort_slots.order(:available_on).to_a
      after = rest.first.available_on

      run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: after.iso8601, days: "7")

      expect(first.reload.available_on).to eq(first.available_on)
      expect(rest.first.reload.available_on).to eq(after + 7)
    end

    { "the picker's format" => "%Y/%m/%d", "ISO" => "%Y-%m-%d" }.each do |label, format|
      it "takes the date in #{label}" do
        slot = cohort.cohort_slots.order(:available_on).last
        after = slot.available_on

        run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: after.strftime(format), days: "2")

        expect(response.body).not_to include("bg-red-400")
        expect(slot.reload.available_on).to eq(after + 2)
      end
    end

    it "takes the date in Arabic-Indic digits, as the picker posts in an Arabic browser locale" do
      slot = cohort.cohort_slots.order(:available_on).last
      after = slot.available_on

      run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: after.strftime("%Y/%m/%d").tr("0-9", "٠-٩"), days: "2")

      expect(response.body).not_to include("bg-red-400")
      expect(slot.reload.available_on).to eq(after + 2)
    end

    it "refuses a shift that would close an open or upcoming exam window, and moves nothing" do
      dates = cohort.cohort_slots.order(:id).pluck(:available_on, :closes_at)
      expect(cohort.exam_slots.where(closes_at: ..Time.current)).to be_empty

      run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: cohort.starts_on.iso8601, days: "-20")

      expect(response.body).to include("bg-red-400")
      expect(response.body).to include("الإزاحة تُغلق نافذة اختبار")
      expect(cohort.cohort_slots.order(:id).pluck(:available_on, :closes_at)).to eq(dates)
    end

    [ "15/11/2025", "2025/02/30", "2025/11/15x", "2025-W46-6", "20251115", "25/11/15", "2025-11/15" ].each do |value|
      it "refuses #{value.inspect} and moves nothing" do
        dates = cohort.cohort_slots.order(:id).pluck(:available_on)

        run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: value, days: "2")

        expect(response.body).to include("bg-red-400")
        expect(response.body).to include("تاريخ غير صحيح")
        expect(cohort.cohort_slots.order(:id).pluck(:available_on)).to eq(dates)
      end
    end

    it "shows an error and moves nothing without a date or days" do
      dates = cohort.cohort_slots.order(:id).pluck(:available_on)

      run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: "", days: "7")
      expect(response.body).to include("bg-red-400")
      run_action("cohorts", Avo::Actions::ShiftCohortSchedule, cohort, after: "2025-11-08", days: "")
      expect(response.body).to include("bg-red-400")

      expect(cohort.cohort_slots.order(:id).pluck(:available_on)).to eq(dates)
    end
  end

  describe "learners" do
    let!(:learner) { create(:learner, full_name: "طالب العلم") }

    it "never shows the password digest or tokens" do
      learner.update_columns(confirmation_token: "confirm-secret", reset_password_token: "reset-secret")

      get "/avo/resources/learners/#{learner.id}"

      expect(response.body).to include("طالب العلم")
      expect(response.body).not_to include(learner.encrypted_password)
      expect(response.body).not_to include("confirm-secret")
      expect(response.body).not_to include("reset-secret")
    end

    it "refuses to create, edit or delete a learner" do
      expect { post "/avo/resources/learners", params: { learner: { full_name: "x", email: "x@example.com" } } }.not_to change(Learner, :count)
      patch "/avo/resources/learners/#{learner.id}", params: { learner: { full_name: "غيره" } }
      delete "/avo/resources/learners/#{learner.id}"
      get "/avo/resources/learners/#{learner.id}/edit"
      expect(response.body).not_to include('name="learner[full_name]"')

      expect(learner.reload.full_name).to eq("طالب العلم")
    end

    it "resets a learner's password" do
      run_action("learners", Avo::Actions::ResetLearnerPassword, learner, password: "new-secret-1")

      expect(learner.reload.valid_password?("new-secret-1")).to be(true)
    end

    it "does not fail when no learner is selected" do
      expect { run_action("learners", Avo::Actions::ResetLearnerPassword, [], password: "new-secret-1") }.not_to raise_error
    end

    it "refuses a too short password" do
      run_action("learners", Avo::Actions::ResetLearnerPassword, learner, password: "1")

      expect(response.body).to include("كلمة المرور قصيرة")
      expect(response.body).not_to include("كلمة المرور كلمة المرور")
      expect(learner.reload.valid_password?("1")).to be(false)
    end
  end

  describe "certificates" do
    let!(:certificate) { create(:certificate, enrollment: create(:enrollment, cohort: cohort, domain: domain)) }

    it "revokes a certificate" do
      run_action("certificates", Avo::Actions::RevokeCertificate, certificate)

      expect(certificate.reload.revoked_at).to be_present
    end

    it "keeps the first revocation time" do
      revoked_at = 2.days.ago.change(usec: 0)
      certificate.update!(revoked_at: revoked_at)

      run_action("certificates", Avo::Actions::RevokeCertificate, certificate)

      expect(certificate.reload.revoked_at).to eq(revoked_at)
    end

    it "refuses to delete a certificate" do
      delete "/avo/resources/certificates/#{certificate.number}"

      expect(Certificate.exists?(certificate.id)).to be(true)
    end
  end
end
