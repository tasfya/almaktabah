FactoryBot.define do
  factory :scholar do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    bio { Faker::Lorem.sentence }

    trait :published do
      published { true }
    end
  end
end
