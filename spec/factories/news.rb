FactoryBot.define do
  factory :news do
    title { Faker::Book.title }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    published_at { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    description { Faker::Lorem.sentence(word_count: 10) }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }

    transient do
      assign_domain { true }
    end

    after(:build) do |news, evaluator|
      if evaluator.assign_domain
        news.domains = [ Domain.find_or_create_by(host: "localhost") ]
      end
    end

    trait :without_domain do
      assign_domain { false }
    end
  end
end
