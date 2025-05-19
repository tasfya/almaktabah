FactoryBot.define do
  factory :series do
    title { Faker::Book.title }
    description { Faker::Lorem.paragraph }
    published_date { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    category { Faker::Book.genre }

    trait :with_lessons do
      lessons { build_list(:lesson, 5) }
    end
  end
end
