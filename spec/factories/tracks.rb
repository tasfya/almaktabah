FactoryBot.define do
  factory :track do
    title { "MyString" }
    description { "MyText" }
    difficulty_level { 1 }
    estimated_hours { 1 }
    position { 1 }
    published { false }
    slug { "MyString" }
    category { 1 }
  end
end
