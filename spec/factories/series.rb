FactoryBot.define do
  factory :series do
    title { Faker::Book.title }
    description { Faker::Lorem.paragraph }
    published_at { Faker::Date.between(from: 2.days.ago, to: Date.today) }
    category { Faker::Book.genre }
    scholar { association(:scholar) }

    trait :with_lessons do
      lessons { build_list(:lesson, 5) }
    end

    after(:create) do |serie|
      serie.domains = [ Domain.find_or_create_by(host: "localhost") ]
    end
  end
end
