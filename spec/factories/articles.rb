FactoryBot.define do
  factory :article do
    title { Faker::Book.title }
    author { association(:scholar) }

    trait :published do
      published { true }
    end
  end
end
