# frozen_string_literal: true

require "rails_helper"

RSpec.describe Learner do
  it "requires full_name and gender" do
    learner = build(:learner, full_name: "", gender: nil)

    expect(learner).not_to be_valid
    expect(learner.errors).to include(:full_name, :gender)
  end

  it "squishes the full name it prints on certificates" do
    expect(build(:learner, full_name: "  عبد   الله  ").full_name).to eq("عبد الله")
  end

  it "caps the full name at 100 characters" do
    expect(build(:learner, full_name: "ا" * 100)).to be_valid
    expect(build(:learner, full_name: "ا" * 101)).not_to be_valid
  end

  it "keeps the email unique regardless of case" do
    create(:learner, email: "taleb@example.com")

    expect(build(:learner, email: "TALEB@example.com")).not_to be_valid
  end

  it "is confirmed on create when learner mail is disabled" do
    allow(Rails.configuration.x).to receive(:learner_mail_enabled).and_return(false)

    expect(create(:learner)).to be_confirmed
  end

  it "is unconfirmed on create when learner mail is enabled" do
    allow(Rails.configuration.x).to receive(:learner_mail_enabled).and_return(true)
    learner = build(:learner)
    learner.skip_confirmation_notification!
    learner.save!

    expect(learner).not_to be_confirmed
  end
end
