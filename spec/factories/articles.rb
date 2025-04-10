FactoryBot.define do
  factory :article do
    title { "MyString" }
    association :author, factory: :scholar
  end
end
