FactoryBot.define do
  factory :series do
    title { Faker::Book.title }
    description { Faker::Lorem.paragraph }
    category { Faker::Book.genre }
    scholar { association(:scholar) }
    published { false }


    trait :with_lessons do
      lessons { create_list(:lesson, 5) }
    end

    transient do
      assign_domain { true }
    end

    after(:create) do |serie, evaluator|
      if evaluator.assign_domain
        serie.domains = [ Domain.find_or_create_by(host: "localhost") ]
      end
    end

    trait :without_domain do
      assign_domain { false }
    end
  end
end
