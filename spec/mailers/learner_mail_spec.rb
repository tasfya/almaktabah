# frozen_string_literal: true

require "rails_helper"

RSpec.describe LearnerMail do
  let(:env) do
    {
      "LEARNER_SMTP_ADDRESS" => "smtp.example.test",
      "LEARNER_SMTP_USERNAME" => "user",
      "LEARNER_SMTP_PASSWORD" => "secret"
    }
  end
  let(:mailer) { Class.new(ActionMailer::Base) }

  before { stub_const("ENV", ENV.to_h.merge(env)) }

  it "applies the SMTP settings from env to the given mailer" do
    described_class.configure!(mailer)

    expect(mailer.delivery_method).to eq(:smtp)
    expect(mailer.smtp_settings).to include(address: "smtp.example.test", port: 587, enable_starttls: true)
    expect(mailer.raise_delivery_errors).to be(true)
  end

  it "does not touch Devise::Mailer or ActionMailer::Base" do
    described_class.configure!(mailer)

    expect(Devise::Mailer.delivery_method).to eq(:test)
    expect(ActionMailer::Base.delivery_method).to eq(:test)
    expect(ActionMailer::Base.smtp_settings).not_to include(address: "smtp.example.test")
  end

  it "leaves the learner mailers on the test delivery method in tests" do
    expect(Learners::Mailer.delivery_method).to eq(:test)
  end
end
