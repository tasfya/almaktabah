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

  factory :cohort do
    program
    sequence(:name) { |n| "Cohort #{n}" }
    starts_on { Date.new(2025, 11, 8) }
  end

  factory :cohort_slot do
    cohort
    program_item { association(:program_item, :lesson, program: cohort.program) }
    available_on { cohort.starts_on }

    trait :exam do
      program_item { association(:program_item, :exam, program: cohort.program) }
      available_on { cohort.starts_on + 11 }
      opens_at { Time.find_zone(cohort.time_zone).local(available_on.year, available_on.month, available_on.day) }
      closes_at { opens_at + 2.days + 22.hours }
    end
  end
end
