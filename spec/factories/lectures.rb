FactoryBot.define do
  factory :lecture do
    title { "#{Faker::Book.unique.title} ##{SecureRandom.hex(3)}" }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 120) }
    category { Faker::Lorem.word }
    published_date { Faker::Date.backward(days: 14) }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    audio { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'audio.mp3'), 'audio/mpeg') }
    thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'files', 'thumbnail.jpg'), 'image/jpeg') }
  end
end
