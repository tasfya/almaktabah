FactoryBot.define do
  factory :article do
    title { Faker::Book.title }
    author { association(:scholar) }
  end
end
