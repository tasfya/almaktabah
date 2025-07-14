FactoryBot.define do
  factory :domain do
    name { Faker::Internet.domain_name }
    host { Faker::Internet.domain_suffix }
    description { Faker::Lorem.sentence }
  end
end
