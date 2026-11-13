FactoryBot.define do
  factory :learner do
    sequence(:email) { |n| "learner#{n}@example.com" }
    password { "password123" }
    full_name { "عبد الله بن محمد" }
    gender { :male }
  end
end
