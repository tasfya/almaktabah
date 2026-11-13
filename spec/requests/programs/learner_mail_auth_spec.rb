# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Learner account mail", type: :request do
  include ActiveJob::TestHelper

  include_context "with tenant domain"
  let(:tenant_host) { "fawzan.3ilm.org" }

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

  def mail_link(mail)
    mail.text_part.body.to_s[%r{https://\S+}]
  end

  describe "with learner mail on" do
    include_context "with learner mail on"

    it "records the sign-up domain and sends one confirmation mail" do
      perform_enqueued_jobs { post learner_registration_path, params: sign_up_params }

      expect(Learner.last.domain).to eq(domain)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ "fatima@example.com" ])
      expect(mail_link(ActionMailer::Base.deliveries.last)).to start_with("https://fawzan.3ilm.org/learners/confirmation?")
    end

    it "lands on the sign-in page with the check-your-email notice" do
      post learner_registration_path, params: sign_up_params

      expect(response).to redirect_to(new_learner_session_path)
      expect(flash[:notice]).to eq(I18n.t("devise.registrations.signed_up_but_unconfirmed"))
    end

    it "cannot sign in before confirming" do
      post learner_registration_path, params: sign_up_params
      post learner_session_path, params: { learner: { email: "fatima@example.com", password: "secret123" } }
      get learner_dashboard_path

      expect(response).to redirect_to(new_learner_session_path)
    end

    it "confirms through the mailed link and signs in" do
      perform_enqueued_jobs { post learner_registration_path, params: sign_up_params }

      get mail_link(ActionMailer::Base.deliveries.last).delete_prefix("https://fawzan.3ilm.org")
      expect(Learner.last).to be_confirmed

      post learner_session_path, params: { learner: { email: "fatima@example.com", password: "secret123" } }
      expect(response).to redirect_to(learner_dashboard_path)
    end

    it "mails a password reset whose link opens on the requesting site" do
      learner = create(:learner, email: "ali@example.com", domain: other_domain)

      perform_enqueued_jobs { post learner_password_path, params: { learner: { email: learner.email } } }

      expect(mail_link(ActionMailer::Base.deliveries.last)).to start_with("https://fawzan.3ilm.org/learners/password/edit?")
    end

    it "leaves staff password reset on Devise::Mailer" do
      user = create(:user)

      perform_enqueued_jobs { user.send_reset_password_instructions }

      mail = ActionMailer::Base.deliveries.last
      expect(mail.from).to eq([ Devise.mailer_sender ])
    end
  end

  describe "with learner mail off" do
    it "sends nothing and confirms on sign-up" do
      perform_enqueued_jobs { post learner_registration_path, params: sign_up_params }

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(Learner.last).to be_confirmed
      expect(Learner.last.domain).to eq(domain)
    end
  end
end
