FactoryBot.define do
  factory :benefit do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 120) }
    category { Faker::Lorem.word }
    published_at { Faker::Date.backward(days: 14) }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }

    trait :with_video do
      video { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'test_video.mp4'), 'video/mp4') }
    end

    trait :without_audio do
      audio { nil }
    end

    trait :without_thumbnail do
      thumbnail { nil }
    end

    after(:create) do |benefit|
      benefit.domains = [ Domain.find_or_create_by(host: "localhost") ]
    end
  end
end
