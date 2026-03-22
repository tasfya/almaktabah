FactoryBot.define do
  factory :scholar do
    transient do
      generated_first { Faker::Name.first_name }
      generated_last { Faker::Name.last_name }
    end
    first_name { generated_first }
    last_name { generated_last }
    full_name { "#{generated_first} #{generated_last}" }
    bio { Faker::Lorem.sentence }
    published { true }
  end
end
