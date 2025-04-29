FactoryBot.define do
  factory :book do
    association :author, factory: :scholar

    after(:build) do |book|
      file_path = Rails.root.join('spec', 'fixtures', 'files', 'sample.pdf')
      if File.exist?(file_path)
        book.file.attach(io: File.open(file_path), filename: 'sample.pdf', content_type: 'application/pdf')
      end
    end
  end
end
