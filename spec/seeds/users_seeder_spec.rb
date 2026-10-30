# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/seeds/users_seeder")

RSpec.describe Seeds::UsersSeeder do
  def admin
    User.find_by!(email: "admin@admin.com")
  end

  around do |example|
    original = ENV.delete("SEED_ADMIN_PASSWORD")
    example.run
  ensure
    ENV["SEED_ADMIN_PASSWORD"] = original
  end

  before { allow($stdout).to receive(:puts) }

  it "seeds the well-known dev password outside production" do
    described_class.seed

    expect(admin.valid_password?("qwerty")).to be(true)
  end

  it "never seeds the well-known password in production" do
    allow(Rails.env).to receive(:production?).and_return(true)

    described_class.seed

    expect(admin.admin).to be(true)
    expect(admin.valid_password?("qwerty")).to be(false)
  end

  it "uses SEED_ADMIN_PASSWORD when given" do
    allow(Rails.env).to receive(:production?).and_return(true)
    ENV["SEED_ADMIN_PASSWORD"] = "a-staging-password"

    described_class.seed

    expect(admin.valid_password?("a-staging-password")).to be(true)
  end
end
