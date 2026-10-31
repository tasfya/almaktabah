FactoryBot.define do
  factory :action_log do
    action { "MyString" }
    actionable { association(:scholar) }
  end
end
