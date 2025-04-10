FactoryBot.define do
  factory :book do
    association :author, factory: :scholar
  end
end
