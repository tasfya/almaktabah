FactoryBot.define do
  factory :news do
    title { Faker::Book.title }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    published_at { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    description { Faker::Lorem.sentence(word_count: 10) }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }

    after(:build) do |news|
      news.domains = [ Domain.find_or_create_by(host: "localhost") ]
    end
  end
end
