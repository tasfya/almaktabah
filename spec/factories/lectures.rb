FactoryBot.define do
  factory :lecture do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 120) }
    category { Faker::Lorem.word }
    kind { Lecture.kinds.keys.sample }
    published { true }
    scholar { association(:scholar) }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
    video { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'test_video.mp4'), 'video/mp4') }

    trait :with_domain do
      after(:build) do |lecture|
        lecture.domains = [ Domain.find_or_create_by(host: "localhost") ]
      end
    end

    trait :without_domain do
      after(:build) do |lecture|
        lecture.domains = []
      end
    end
  end
end
