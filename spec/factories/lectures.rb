FactoryBot.define do
  factory :lecture do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 120) }
    category { Faker::Lorem.word }
    views { Faker::Number.between(from: 0, to: 1000) }
    published_date { Faker::Date.backward(days: 14) }
    audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
  end
end
