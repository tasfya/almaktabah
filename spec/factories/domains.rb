FactoryBot.define do
  factory :domain do
    name { Faker::Internet.domain_name }
    title { Faker::Company.name }
    sequence(:host) { |n| "site#{n}.example.test" }
    description { Faker::Lorem.sentence }
  end
end
