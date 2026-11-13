require "rails_helper"

RSpec.describe "Learner account", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  include_context "with tenant domain"

  let(:learner) { create(:learner, full_name: "محمد بن عبد الله", gender: :male, password: "secret123", domain: domain, confirmed_at: Time.current) }
  let(:program) { create(:program, published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program) }
  let!(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }

  it "requires a signed-in learner" do
    get learner_account_path

    expect(response).to redirect_to(new_learner_session_path)
  end

  context "when signed in" do
    before { sign_in learner }

    it "shows the account page without caching it" do
      get learner_account_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("محمد بن عبد الله", program.title)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "updates full_name and gender, leaving issued certificates unchanged" do
      certificate = create(:certificate, enrollment: enrollment)

      patch learner_account_path, params: { learner: { full_name: "  أحمد  بن علي ", gender: "female", email: "x@example.com" } }

      expect(response).to redirect_to(learner_account_path)
      expect(learner.reload).to have_attributes(full_name: "أحمد بن علي", gender: "female", email: learner.email)
      expect(certificate.reload).to have_attributes(full_name_snapshot: "محمد بن عبد الله", gender_snapshot: "male")
    end

    it "re-renders the form when the name is blank" do
      patch learner_account_path, params: { learner: { full_name: " ", gender: "male" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(learner.reload.full_name).to eq("محمد بن عبد الله")
    end

    it "toggles reminders for one enrollment" do
      other = create(:enrollment, learner: learner, cohort: create(:cohort, program: program), domain: domain)

      patch learner_cohort_reminders_path(cohort), params: { reminders_enabled: "0" }

      expect(response).to redirect_to(learner_account_path)
      expect(enrollment.reload.reminders_enabled).to be(false)
      expect(other.reload.reminders_enabled).to be(true)

      patch learner_cohort_reminders_path(cohort), params: { reminders_enabled: "1" }
      expect(enrollment.reload.reminders_enabled).to be(true)
    end

    it "cannot toggle reminders on another learner's enrollment" do
      foreign = create(:enrollment, cohort: create(:cohort, program: program), domain: domain)

      patch learner_cohort_reminders_path(foreign.cohort), params: { reminders_enabled: "0" }

      expect(response).to have_http_status(:not_found)
      expect(foreign.reload.reminders_enabled).to be(true)
    end

    it "lists and toggles only this site's enrollments" do
      elsewhere = create(:program, title: "برنامج موقع آخر", published: true).tap { |p| p.update!(domains: [ other_domain ]) }
      other_site = create(:enrollment, learner: learner, cohort: create(:cohort, program: elsewhere), domain: other_domain)

      get learner_account_path
      expect(response.body).not_to include("برنامج موقع آخر")

      patch learner_cohort_reminders_path(other_site.cohort), params: { reminders_enabled: "0" }
      expect(response).to have_http_status(:not_found)
      expect(other_site.reload.reminders_enabled).to be(true)
    end

    it "deletes the account, its enrollments and progress, and keeps certificate numbers as revoked" do
      lesson_item = create(:program_item, :lesson, program: program, position: 1)
      create(:lesson_completion, enrollment: enrollment, program_item: lesson_item)
      exam = create(:exam, :with_questions, program: program)
      attempt = create(:exam_attempt, enrollment: enrollment, exam: exam, started_at: Time.current)
      question = exam.questions.first
      AttemptAnswer.create!(exam_attempt: attempt, question: question, choice: question.choices.first)
      certificate = create(:certificate, enrollment: enrollment)

      delete learner_account_path, params: { current_password: "secret123" }

      expect(response).to redirect_to(new_learner_session_path)
      expect(Learner.exists?(learner.id)).to be(false)
      expect(Enrollment.where(learner_id: learner.id)).to be_empty
      expect(LessonCompletion.count).to eq(0)
      expect(ExamAttempt.count).to eq(0)
      expect(AttemptAnswer.count).to eq(0)
      expect(certificate.reload).to have_attributes(enrollment_id: nil, number: certificate.number)
      expect(certificate.revoked_at).to be_present

      get learner_dashboard_path
      expect(response).to redirect_to(new_learner_session_path)
    end

    it "refuses to delete the account with a wrong password" do
      delete learner_account_path, params: { current_password: "wrong" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Learner.exists?(learner.id)).to be(true)
    end

    context "with learner mail on" do
      include_context "with learner mail on"

      it "deletes the account without sending mail" do
        expect { delete learner_account_path, params: { current_password: "secret123" } }
          .not_to have_enqueued_job

        expect(Learner.exists?(learner.id)).to be(false)
      end
    end
  end
end
