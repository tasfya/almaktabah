FactoryBot.define do
  factory :scholar do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    after(:build) do |scholar|
      scholar.bio = ActionText::RichText.new(body: Faker::Lorem.paragraphs.join("\n\n"))
    end
  end
end
