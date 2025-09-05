require 'factory_bot'

FactoryBot.define do
  trait :published do
    published { true }
    published_at { Faker::Date.backward(days: 14) }
  end

  trait :unpublished do
    published { false }
    published_at { nil }
  end
end
