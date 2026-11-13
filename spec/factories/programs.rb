FactoryBot.define do
  factory :program do
    sequence(:title) { |n| "Program #{n}" }
    description { Faker::Lorem.paragraph }
  end

  factory :program_item do
    program
    sequence(:position)
    kind { :lesson }
    lesson

    trait :lesson do
      kind { :lesson }
      lesson
    end

    trait :book do
      kind { :book }
      lesson { nil }
      book
    end
  end
end
