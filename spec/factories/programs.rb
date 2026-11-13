FactoryBot.define do
  factory :program do
    sequence(:title) { |n| "Program #{n}" }
    description { Faker::Lorem.paragraph }
  end

  factory :program_item do
    program
    sequence(:position)
    kind { :lesson }
    lesson

    trait :lesson do
      kind { :lesson }
      lesson
    end

    trait :book do
      kind { :book }
      lesson { nil }
      book
    end

    trait :exam do
      kind { :exam }
      lesson { nil }
      exam { association(:exam, program: program) }
    end
  end

  factory :exam do
    program
    sequence(:title) { |n| "Exam #{n}" }

    trait :with_questions do
      after(:create) do |exam|
        3.times do |q|
          question = create(:question, exam: exam, position: q + 1)
          3.times { |c| create(:choice, question: question, position: c + 1, correct: c.zero?) }
        end
        exam.questions.reset
      end
    end
  end

  factory :question do
    exam
    sequence(:position)
    kind { :single_choice }
    body { Faker::Lorem.question }
  end

  factory :choice do
    question
    sequence(:position)
    body { Faker::Lorem.word }
    correct { false }
  end
end
