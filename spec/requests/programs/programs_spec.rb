require "rails_helper"

RSpec.describe "Programs", type: :request do
  include Devise::Test::IntegrationHelpers

  include_context "with tenant domain"

  let(:learner) { create(:learner) }

  def program_on(target_domain, published: true, **attributes)
    create(:program, published: published, **attributes).tap { |program| program.update!(domains: [ target_domain ]) }
  end

  describe "GET /البرامج" do
    it "lists published programs assigned to this domain only" do
      program_on(domain, title: "متون التوحيد")
      program_on(domain, title: "برنامج مخفي", published: false)
      program_on(other_domain, title: "برنامج موقع آخر")

      get "/#{URI::DEFAULT_PARSER.escape("البرامج")}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("متون التوحيد")
      expect(response.body).not_to include("برنامج مخفي", "برنامج موقع آخر")
    end

    it "is cacheable for guests but not for a signed-in learner" do
      allow_any_instance_of(ProgramsController).to receive(:perform_caching).and_return(true) # rubocop:disable RSpec/AnyInstance
      get programs_path
      expect(response.headers["Cache-Control"]).to include("public")

      sign_in learner
      get programs_path
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  describe "GET /البرامج/:slug" do
    let(:program) { program_on(domain, title: "متون التوحيد", description: "شرح المتون") }

    it "shows the program with its texts and scholars, never its hidden books" do
      lesson = create(:lesson, published: false)
      create(:program_item, :lesson, program: program, lesson: lesson)
      create(:program_item, :book, program: program, book: create(:book, title: "متن القواعد الأربع"))
      create(:program_item, :book, program: program, book: create(:book, title: "تفريغ سري"), hidden: true)

      get program_path(program)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("متون التوحيد", "شرح المتون", "متن القواعد الأربع", lesson.series.scholar.name)
      expect(response.body).not_to include("تفريغ سري")
    end

    it "is never publicly cached, since it carries the enroll form" do
      allow_any_instance_of(ProgramsController).to receive(:perform_caching).and_return(true) # rubocop:disable RSpec/AnyInstance
      get program_path(program)
      expect(response.headers["Cache-Control"]).not_to include("public")
    end

    it "shows the not-found page for a program on another domain" do
      foreign = program_on(other_domain)
      get program_path(foreign)
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(foreign.title)
    end

    it "shows the not-found page for an unpublished program to the public" do
      hidden = program_on(domain, published: false)
      get program_path(hidden)
      expect(response).to have_http_status(:not_found)
    end

    it "shows an unpublished program to a signed-in admin, with noindex" do
      hidden = program_on(domain, published: false)
      sign_in create(:user, admin: true)

      get program_path(hidden)

      expect(response).to have_http_status(:ok)
      expect(response).to have_meta_tag("robots", a_string_including("noindex"))
    end

    it "lists open cohorts with an enroll button and hides closed ones" do
      create(:cohort, program: program, name: "دفعة مفتوحة")
      create(:cohort, program: program, name: "دفعة مغلقة", enrollment_closes_at: 1.day.ago)

      get program_path(program)

      expect(response.body).to include("دفعة مفتوحة")
      expect(response.body).not_to include("دفعة مغلقة")
    end

    it "links an enrolled learner to their cohort instead of the enroll button" do
      cohort = create(:cohort, program: program)
      create(:enrollment, learner: learner, cohort: cohort, domain: domain)
      sign_in learner

      get program_path(program)

      expect(response.body).to include(learner_cohort_path(cohort))
    end
  end

  describe "POST /البرامج/:slug/enrollments" do
    let(:program) { program_on(domain) }
    let(:cohort) { create(:cohort, program: program) }

    it "redirects a guest who tries to enroll to sign in, then back to the program" do
      post program_enrollments_path(program), params: { cohort_id: cohort.id }

      expect(response).to redirect_to(new_learner_session_path)
      expect(Enrollment.count).to eq(0)

      post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }
      expect(response).to redirect_to(program_path(program))
    end

    it "enrolls a learner in an open cohort and records the domain" do
      sign_in learner

      post program_enrollments_path(program), params: { cohort_id: cohort.id }

      expect(response).to redirect_to(learner_cohort_path(cohort))
      expect(Enrollment.last).to have_attributes(learner: learner, cohort: cohort, domain: domain)
    end

    it "sends an already enrolled learner to their cohort without a second enrollment" do
      create(:enrollment, learner: learner, cohort: cohort, domain: domain)
      sign_in learner

      post program_enrollments_path(program), params: { cohort_id: cohort.id }

      expect(response).to redirect_to(learner_cohort_path(cohort))
      expect(Enrollment.count).to eq(1)
    end

    it "refuses enrolling in a closed cohort" do
      cohort.update!(enrollment_closes_at: 1.minute.ago)
      sign_in learner

      post program_enrollments_path(program), params: { cohort_id: cohort.id }

      expect(response).to redirect_to(program_path(program))
      expect(flash[:alert]).to be_present
      expect(Enrollment.count).to eq(0)
    end

    it "refuses a cohort of another program" do
      sign_in learner
      post program_enrollments_path(program), params: { cohort_id: create(:cohort).id }
      expect(response).to have_http_status(:not_found)
      expect(Enrollment.count).to eq(0)
    end

    it "refuses a program of another domain" do
      foreign = program_on(other_domain)
      sign_in learner
      post program_enrollments_path(foreign), params: { cohort_id: create(:cohort, program: foreign).id }
      expect(response).to have_http_status(:not_found)
      expect(Enrollment.count).to eq(0)
    end
  end

  describe "with the launch switch off" do
    around do |example|
      Rails.configuration.x.learners_enabled = false
      example.run
    ensure
      Rails.configuration.x.learners_enabled = true
    end

    it "does not route the program pages" do
      get "/#{URI::DEFAULT_PARSER.escape("البرامج")}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
