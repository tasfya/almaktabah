require 'factory_bot'

FactoryBot.define do
  trait :published do
    published { true }
    after(:build) do |record|
      if record.respond_to?(:published_at=)
        record.published_at ||= Faker::Date.backward(days: 14)
      end
    end
  end

  trait :unpublished do
    published { false }
    published_at { nil }
  end
end
