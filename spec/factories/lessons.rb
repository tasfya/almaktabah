FactoryBot.define do
    factory :lesson do
        title { "#{Faker::Book.unique.title} ##{SecureRandom.hex(3)}" }
        description { Faker::Lorem.paragraph }
        content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
        published_date { Faker::Date.between(from: 2.days.ago, to: Date.today) }
        duration { Faker::Number.between(from: 1, to: 100) }
        category { Faker::Book.genre }
        thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
        audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
        created_at { Time.now }
        updated_at { Time.now }
        after(:build) do |lesson|
            lesson.series ||= create(:series) if lesson.series.nil?
        end
    end
end
