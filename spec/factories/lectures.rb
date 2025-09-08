FactoryBot.define do
  factory :lecture do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 120) }
    category { Faker::Lorem.word }
    kind { :conference }
    published { true }
    scholar { association(:scholar) }
    published_at { Faker::Date.backward(days: 14) }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }

    trait :with_domain do
      after(:build) do |lecture|
        lecture.domains = [ Domain.find_or_create_by(host: "localhost") ]
      end
    end

    trait :with_video do
      video { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'test_video.mp4'), 'video/mp4') }
      audio { nil }
    end

    trait :with_youtube_url do
      youtube_url { "https://www.youtube.com/watch?v=#{Faker::Alphanumeric.alphanumeric(number: 11)}" }
    end

    trait :with_video_url do
      video_url { "https://example.com/videos/#{Faker::Alphanumeric.alphanumeric(number: 8)}.mp4" }
    end

    trait :with_video_from_url do
      transient do
        video_download_url { "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4" }
      end

      after(:create) do |lecture, evaluator|
        if evaluator.video_download_url.present?
          MediaDownloadJob.perform_now(lecture, :video, evaluator.video_download_url, 'video/mp4')
        end
      end
    end

    trait :without_audio do
      audio { nil }
    end
  end
end
