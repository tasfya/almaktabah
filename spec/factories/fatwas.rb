FactoryBot.define do
  factory :fatwa do
      scholar
      title { Faker::Book.title }
      question { Faker::Lorem.paragraph }
      answer { Faker::Lorem.paragraphs(number: 20).join("\n\n") }
      published
      category { Faker::Book.genre }
      created_at { Time.now }
      updated_at { Time.now }


      transient do
        assign_domain { true }
      end

      after(:create) do |fatwa, evaluator|
        if evaluator.assign_domain
          fatwa.domains = [ Domain.find_or_create_by(host: "localhost") ]
        end
      end

      trait :without_domain do
        assign_domain { false }
      end
  end
end
