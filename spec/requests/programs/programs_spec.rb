require "rails_helper"

RSpec.describe "Programs", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

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

    it "shows each program's scholars, counts and next cohort on its card" do
      program = program_on(domain, title: "متون التوحيد")
      create(:program_item, :lesson, program: program, position: 1)
      create(:cohort, program: program, starts_on: Date.current + 10)

      get programs_path

      card = Nokogiri::HTML(response.body).at_css("a[href='#{program_path(program)}']").text.squish
      expect(card).to include("درس واحد", "الدفعة القادمة تبدأ")
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
      expect(response.body).to include("متون التوحيد", "شرح المتون", "متن القواعد الأربع", ERB::Util.h(lesson.series.scholar.name))
      expect(response.body).not_to include("تفريغ سري")
    end

    it "is never publicly cached, since it carries the enroll form" do
      allow_any_instance_of(ProgramsController).to receive(:perform_caching).and_return(true) # rubocop:disable RSpec/AnyInstance
      get program_path(program)
      expect(response.headers["Cache-Control"]).not_to include("public")
      expect(response).to have_meta_tag("turbo-cache-control", "no-cache")
    end

    it "shows the not-found page for a program on another domain" do
      foreign = program_on(other_domain)
      get program_path(foreign)
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(ERB::Util.h(foreign.title))
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
      create(:cohort, program: hidden)
      get program_path(hidden)
      expect(response.body).not_to include(program_enrollments_path(hidden))
      expect(Array(session[:breadcrumbs]).to_s).not_to include(hidden.title)
    end

    it "lists open cohorts with an enroll button and hides closed ones" do
      create(:cohort, program: program, name: "دفعة مفتوحة")
      create(:cohort, program: program, name: "دفعة مغلقة", enrollment_closes_at: 1.day.ago)

      get program_path(program)

      expect(response.body).to include("دفعة مفتوحة")
      expect(response.body).not_to include("دفعة مغلقة")
    end

    it "links an enrolled learner to their cohort, even after enrollment closed" do
      cohort = create(:cohort, program: program, enrollment_closes_at: 1.day.ago)
      create(:enrollment, learner: learner, cohort: cohort, domain: domain)
      sign_in learner

      get program_path(program)

      expect(response.body).to include(learner_cohort_path(cohort))
    end

    it "explains how the program works, with its counts, pass mark and each cohort's dates" do
      program.update!(pass_mark: 70)
      2.times { |n| create(:program_item, :lesson, program: program, position: n + 1) }
      create(:program_item, :exam, program: program, position: 3, exam: create(:exam, program: program))
      create(:cohort, program: program, name: "دفعة بدأت", starts_on: Date.current - 3, enrollment_closes_at: 2.weeks.from_now)

      get program_path(program)

      text = Nokogiri::HTML(response.body).text.squish
      expect(text).to include("درسان · اختبار واحد", "كيف يعمل البرنامج", "بنسبة 70٪ فأكثر", "بدأت ", "التسجيل مفتوح حتى")
    end

    it "links a text only when its book is published on this site" do
      here = create(:book, title: "متن منشور هنا", published: true).tap { |b| b.update!(domains: [ domain ]) }
      elsewhere = create(:book, title: "متن موقع آخر", published: true).tap { |b| b.update!(domains: [ other_domain ]) }
      create(:program_item, :book, program: program, position: 1, book: here)
      create(:program_item, :book, program: program, position: 2, book: elsewhere)

      get program_path(program)

      links = Nokogiri::HTML(response.body).css("a").map(&:text)
      expect(links).to include("متن منشور هنا")
      expect(links).not_to include("متن موقع آخر")
    end

    it "addresses guests neutrally and a signed-in learner by gender" do
      create(:cohort, program: program)

      get program_path(program)
      expect(response.body).to include("الالتحاق بالدفعة")

      sign_in create(:learner, gender: :female)
      get program_path(program)
      expect(response.body).to include("التحقي بالدفعة")
    end
  end

  describe "POST /البرامج/:slug/enrollments" do
    let(:program) { program_on(domain) }
    let(:cohort) { create(:cohort, program: program) }

    describe "as a guest" do
      let(:sign_up_params) do
        { learner: { full_name: "فاطمة بنت أحمد", gender: "female", email: "fatima@example.com",
                     password: "password123", password_confirmation: "password123" } }
      end

      it "sends the guest to sign up with a neutral notice naming the cohort, and enrolls them after sign-up" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }

        expect(response).to redirect_to(new_learner_registration_path)
        expect(Enrollment.count).to eq(0)

        follow_redirect!
        notice = Nokogiri::HTML(response.body).at_css(".alert-info")
        expect(notice.text).to include(program.title, cohort.name)
        expect(response.body).not_to include("alert-error")

        post learner_registration_path, params: sign_up_params
        expect(response).to redirect_to(learner_cohort_path(cohort))
        expect(Learner.last.enrollments.sole).to have_attributes(cohort: cohort, domain: domain)
        expect(flash[:notice]).to eq(I18n.t("programs.enrollments.enrolled"))
      end

      it "keeps the cohort through a failed sign-up and enrolls on sign-in instead" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }
        post learner_registration_path, params: { learner: sign_up_params[:learner].merge(full_name: "") }
        expect(response).to have_http_status(:unprocessable_content)
        expect(Nokogiri::HTML(response.body).at_css(".alert-info").text).to include(program.title)

        post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }
        expect(response).to redirect_to(learner_cohort_path(cohort))
        expect(learner.enrollments.sole.cohort).to eq(cohort)
      end

      it "forgets a stale request, so a later sign-in doesn't enroll" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }

        travel(PendingEnrollment::TTL + 1.minute) do
          post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }
        end

        expect(response).to redirect_to(program_path(program))
        expect(Enrollment.count).to eq(0)
      end

      it "doesn't enroll when the program was unpublished in the meantime" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }
        program.update!(published: false)

        post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }

        expect(response).not_to redirect_to(learner_cohort_path(cohort))
        expect(Enrollment.count).to eq(0)
      end

      it "doesn't carry the request to another site" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }
        program.update!(domains: [ other_domain ])

        post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }

        expect(Enrollment.count).to eq(0)
      end

      it "doesn't enroll when the cohort closed in the meantime" do
        post program_enrollments_path(program), params: { cohort_id: cohort.id }
        cohort.update!(enrollment_closes_at: 1.minute.ago)

        post learner_session_path, params: { learner: { email: learner.email, password: "password123" } }

        expect(response).to redirect_to(program_path(program))
        expect(flash[:alert]).to eq(I18n.t("programs.enrollments.closed"))
        expect(Enrollment.count).to eq(0)
      end
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

    it "sends a learner already in a closed cohort to it, not to an alert" do
      create(:enrollment, learner: learner, cohort: cohort, domain: domain)
      cohort.update!(enrollment_closes_at: 1.minute.ago)
      sign_in learner

      post program_enrollments_path(program), params: { cohort_id: cohort.id }

      expect(response).to redirect_to(learner_cohort_path(cohort))
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
