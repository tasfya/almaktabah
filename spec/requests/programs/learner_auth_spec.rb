# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Learner accounts", type: :request do
  include Devise::Test::IntegrationHelpers

  include_context "with tenant domain"

  let(:sign_up_params) do
    {
      learner: {
        full_name: "فاطمة بنت أحمد",
        gender: "female",
        email: "fatima@example.com",
        password: "secret123",
        password_confirmation: "secret123"
      }
    }
  end

  describe "with the launch switch on" do
    it "renders the Arabic sign-up form with the gender choice" do
      get new_learner_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("إنشاء حساب طالب", 'name="learner[gender]"', 'value="female"')
    end

    it "signs up with name and gender and lands on /my" do
      post learner_registration_path, params: sign_up_params

      expect(response).to redirect_to(learner_dashboard_path)
      expect(Learner.last).to have_attributes(full_name: "فاطمة بنت أحمد", gender: "female")

      follow_redirect!
      expect(response.body).to include("فاطمة بنت أحمد")
    end

    it "rerenders the form with Arabic errors when the name is missing" do
      post learner_registration_path, params: { learner: sign_up_params[:learner].merge(full_name: "") }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("الاسم الكامل لا يمكن أن يكون فارغًا")
      expect(Learner.count).to eq(0)
    end

    it "signs in and lands on /my" do
      learner = create(:learner, password: "secret123")

      post learner_session_path, params: { learner: { email: learner.email, password: "secret123" } }

      expect(response).to redirect_to(learner_dashboard_path)
    end

    it "sends a visitor without a session to the learner sign-in page" do
      get learner_dashboard_path

      expect(response).to redirect_to(new_learner_session_path)
    end

    it "sends Cache-Control no-store on /my" do
      sign_in create(:learner)

      get learner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "does not grant Avo access" do
      sign_in create(:learner)

      get "/avo"

      expect(response).to redirect_to("http://localhost/users/sign_in")
    end

    it "a staff User cannot sign in through the learner form" do
      user = create(:user, admin: true, password: "password123")

      post learner_session_path, params: { learner: { email: user.email, password: "password123" } }
      get learner_dashboard_path

      expect(response).to redirect_to(new_learner_session_path)
    end

    it "keeps staff sign-in on the staff page and away from /my" do
      user = create(:user, admin: true, password: "password123")

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).not_to redirect_to(learner_dashboard_path)
      get learner_dashboard_path
      expect(response).to redirect_to(new_learner_session_path)
    end

    it "re-renders the form instead of failing on an unknown gender" do
      post learner_registration_path, params: { learner: sign_up_params[:learner].merge(gender: "other") }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Learner.count).to eq(0)
    end

    it "signs a learner out without ending the staff session" do
      sign_in create(:user, admin: true)
      sign_in create(:learner)

      delete destroy_learner_session_path
      get "/avo"
      follow_redirect! while response.redirect?

      expect(request.path).to start_with("/avo")
      expect(response).to have_http_status(:ok)
    end

    it "offers no password reset or confirmation while learner mail is off" do
      get "/learners/sign_in"
      expect(response.body).not_to include("/learners/password/new")

      get "/learners/password/new"
      expect(response).to have_http_status(:not_found)

      email = create(:learner).email
      expect { post "/learners/password", params: { learner: { email: email } } }
        .not_to change(ActionMailer::Base.deliveries, :count)
      expect(response).to have_http_status(:not_found)

      get "/learners/confirmation/new"
      expect(response).to have_http_status(:not_found)
    end

    it "offers only sign-up, not account edit or deletion" do
      learner = create(:learner)
      sign_in learner

      get "/learners/edit"
      expect(response).to have_http_status(:not_found)

      delete "/learners"
      expect(response).to have_http_status(:not_found)
      expect(Learner.exists?(learner.id)).to be(true)
    end
  end

  describe "with learner mail on" do
    around do |example|
      Rails.configuration.x.learner_mail_enabled = true
      Rails.application.reload_routes!
      example.run
    ensure
      Rails.configuration.x.learner_mail_enabled = false
      Rails.application.reload_routes!
    end

    it "offers password reset" do
      get "/learners/sign_in"
      expect(response.body).to include("/learners/password/new")

      get "/learners/password/new"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "with the launch switch off" do
    around do |example|
      Rails.configuration.x.learners_enabled = false
      example.run
    ensure
      Rails.configuration.x.learners_enabled = true
    end

    %w[/my /learners/sign_up /learners/sign_in /learners/password/new].each do |path|
      it "returns not found for GET #{path}" do
        get path

        expect(response).to have_http_status(:not_found)
      end
    end

    it "does not accept a sign-up" do
      post "/learners", params: sign_up_params

      expect(response).to have_http_status(:not_found)
      expect(Learner.count).to eq(0)
    end

    it "keeps staff sign-in working" do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end

    it "still defines the learner helpers for shared pages" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(controller.learner_signed_in?).to be(false)
      expect(controller.current_learner).to be_nil
    end
  end

  describe "rate limiting" do
    let(:counter) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Controllers capture the (null, in test) cache store when they load.
      allow(ApplicationController.cache_store).to receive(:increment) { |*args, **opts| counter.increment(*args, **opts) }
    end

    def sign_up_as(email)
      post learner_registration_path, params: { learner: sign_up_params[:learner].merge(email: email) }
    end

    it "lets more than 10 learners sign up from one shared address" do
      11.times do |n|
        sign_up_as("learner#{n}@example.com")
        delete destroy_learner_session_path
      end

      expect(Learner.count).to eq(11)
    end

    it "stops repeated sign-up attempts with one email" do
      10.times { post learner_registration_path, params: { learner: sign_up_params[:learner].merge(full_name: "") } }

      post learner_registration_path, params: sign_up_params

      expect(response).to redirect_to(new_learner_registration_path)
      expect(flash[:alert]).to eq(I18n.t("programs.learner_auth.rate_limited"))
      expect(Learner.count).to eq(0)
    end

    it "stops sign-up after 60 attempts from one address" do
      60.times { |n| post learner_registration_path, params: { learner: sign_up_params[:learner].merge(email: "x#{n}@example.com", full_name: "") } }

      sign_up_as("late@example.com")

      expect(flash[:alert]).to eq(I18n.t("programs.learner_auth.rate_limited"))
      expect(Learner.count).to eq(0)
    end

    it "stops sign-in after 10 attempts on one email, whatever the case" do
      learner = create(:learner, password: "secret123")
      10.times { post learner_session_path, params: { learner: { email: learner.email.upcase, password: "wrong" } } }

      post learner_session_path, params: { learner: { email: learner.email, password: "secret123" } }

      expect(response).to redirect_to(new_learner_session_path)
      get learner_dashboard_path
      expect(response).to redirect_to(new_learner_session_path)
    end

    it "still lets another learner on the same address sign in" do
      neighbour = create(:learner, password: "secret123")
      10.times { post learner_session_path, params: { learner: { email: "someone@example.com", password: "wrong" } } }

      post learner_session_path, params: { learner: { email: neighbour.email, password: "secret123" } }

      get learner_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "counts two visitors behind one Cloudflare edge separately" do
      learner = create(:learner, password: "secret123")
      via_edge = ->(visitor) { { "X-Forwarded-For" => "172.71.178.144", "CF-Connecting-IP" => visitor } }
      60.times { |n| post learner_session_path, params: { learner: { email: "guess#{n}@example.com", password: "wrong" } }, headers: via_edge.call("203.0.113.1") }

      post learner_session_path, params: { learner: { email: learner.email, password: "secret123" } }, headers: via_edge.call("203.0.113.2")

      get learner_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "stops sign-in after 60 attempts from one address" do
      learner = create(:learner, password: "secret123")
      60.times { |n| post learner_session_path, params: { learner: { email: "guess#{n}@example.com", password: "wrong" } } }

      post learner_session_path, params: { learner: { email: learner.email, password: "secret123" } }

      get learner_dashboard_path
      expect(response).to redirect_to(new_learner_session_path)
    end
  end
end
