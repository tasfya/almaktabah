FactoryBot.define do
  factory :news do
    title { Faker::Book.title }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    description { Faker::Lorem.sentence(word_count: 10) }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
    published

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
