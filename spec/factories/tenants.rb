FactoryBot.define do
  factory :tenant do
    subdomain { Faker::Internet.domain_word }
    name { Faker::Company.name }
    logo_light { nil }
    logo_dark { nil }
  end
end
