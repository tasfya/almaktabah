FactoryBot.define do
  factory :domain_assignment do
    assignable { association(:book) }
    domain
  end
end
