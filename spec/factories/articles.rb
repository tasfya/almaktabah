FactoryBot.define do
  factory :article do
    title { Faker::Book.title }
    scholar { association(:scholar) }
    published
  end
end
