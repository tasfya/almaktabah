FactoryBot.define do
  factory :fatwa do
      title { Faker::Book.title }
      question { Faker::Lorem.paragraph }
      answer { Faker::Lorem.paragraphs(number: 20).join("\n\n") }
      published_date { Faker::Date.between(from: 2.days.ago, to: Date.today) }
      category { Faker::Book.genre }
      views { Faker::Number.between(from: 1, to: 1000) }
      created_at { Time.now }
      updated_at { Time.now }
  end
end
