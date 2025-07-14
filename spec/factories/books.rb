FactoryBot.define do
  factory :book do
    title { "#{Faker::Book.title} #{SecureRandom.hex(4)}" }

    description { Faker::Lorem.paragraph }
    category { Faker::Book.genre }
    published_at { Faker::Date.between(from: 2.years.ago, to: Date.today) }
    pages { rand(1..1000) }
    downloads { rand(1..1000) }

    author { association(:scholar) }

    after(:build) do |book|
      file_path = Rails.root.join('spec', 'files', 'sample.pdf')
      if File.exist?(file_path)
        book.file.attach(io: File.open(file_path), filename: 'sample.pdf', content_type: 'application/pdf')
      end

      cover_image_path = Rails.root.join('spec', 'files', 'thumbnail.jpg')
      if File.exist?(cover_image_path)
        book.cover_image.attach(io: File.open(cover_image_path), filename: 'thumbnail.jpg', content_type: 'image/jpeg')
      end

      book.domains = [ Domain.find_or_create_by(host: "localhost") ]
    end
  end
end
