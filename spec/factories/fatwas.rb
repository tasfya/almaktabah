FactoryBot.define do
  factory :fatwa do
      title { Faker::Book.title }
      question { Faker::Lorem.paragraph }
      answer { Faker::Lorem.paragraphs(number: 20).join("\n\n") }
      published_at { Faker::Date.between(from: 2.days.ago, to: Date.today) }
      category { Faker::Book.genre }
      created_at { Time.now }
      updated_at { Time.now }
      after(:create) do |fatwa|
        fatwa.domains = [ Domain.find_or_create_by(host: "localhost") ]
      end
  end
end
