FactoryBot.define do
    factory :lesson do
        title { "#{Faker::Book.title} ##{SecureRandom.hex(6)}" }
        description { Faker::Lorem.paragraph }
        content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
        duration { Faker::Number.between(from: 1, to: 100) }
        thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
        audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
        created_at { Time.now }
        updated_at { Time.now }
        published
        after(:build) do |lesson|
          lesson.series ||= create(:series) if lesson.series.nil?
        end


    trait :with_video do
      video { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'test_video.mp4'), 'video/mp4') }
    end

    trait :without_audio do
      audio { nil }
    end

    trait :without_domain do
      after(:create) do |lesson|
        lesson.domains = []
      end
    end

    after(:create) do |lesson|
        lesson.domains = [ Domain.find_or_create_by(host: "localhost") ]
    end
    end
end
