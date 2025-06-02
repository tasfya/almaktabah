FactoryBot.define do
  factory :api_token do
    token { SecureRandom.hex(24) }
    association :user
    purpose { "Test API Token" }
    last_used_at { nil }
    expires_at { 1.year.from_now }
    active { true }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :inactive do
      active { false }
    end
  end
end
