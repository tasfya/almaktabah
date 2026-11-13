module Seeds
  # A small program for trying the learner pages in development: a matn, two
  # lessons released today, an exam whose window is open, and one lesson
  # released tomorrow. A second cohort has no exam and everything released
  # today, to reach a certificate. Re-running moves both cohorts to today.
  class ProgramsSeeder
    TITLE = "برنامج تجريبي: القواعد الأربع"

    def self.seed(domain:)
      lessons = Lesson.order(:id).limit(3).to_a
      book = Book.order(:id).first
      return puts("⚠️ Skipping the dev program: it needs 3 lessons and a book") if lessons.size < 3 || book.nil?

      program = Program.find_by(title: TITLE) || build_program(lessons, book)
      program.update!(published: true, domains: [ domain ])
      schedule(program)
      schedule_certificate_cohort(program)
      puts "✅ Dev program: #{program.title}"
    end

    def self.build_program(lessons, book)
      Program.transaction do
        program = Program.create!(title: TITLE, description: "برنامج قصير لتجربة صفحات الطلاب: متن، ودروس، واختبار، وشهادة.")
        exam = program.exams.create!(title: "اختبار القواعد الأربع")
        add_questions(exam)

        program.program_items.create!(position: 1, kind: :book, book: book)
        program.program_items.create!(position: 2, kind: :lesson, lesson: lessons[0])
        program.program_items.create!(position: 3, kind: :lesson, lesson: lessons[1])
        program.program_items.create!(position: 4, kind: :exam, exam: exam)
        program.program_items.create!(position: 5, kind: :lesson, lesson: lessons[2])
        program
      end
    end

    def self.add_questions(exam)
      [
        [ "كم عدد القواعد في رسالة القواعد الأربع؟", [ "أربع", "ثلاث", "خمس" ] ],
        [ "من مؤلف رسالة القواعد الأربع؟", [ "الشيخ محمد بن عبد الوهاب", "ابن تيمية", "ابن القيم" ] ],
        [ "العبادة لا تسمى عبادة إلا مع:", [ "التوحيد", "الصيام", "الصدقة" ] ]
      ].each.with_index(1) do |(body, choices), position|
        question = exam.questions.new(position: position, body: body, kind: :single_choice)
        choices.each.with_index(1) { |choice, index| question.choices.new(position: index, body: choice, correct: index == 1) }
        question.save!
      end
    end

    def self.schedule(program)
      cohort = program.cohorts.find_or_initialize_by(name: "الدفعة التجريبية")
      zone = ActiveSupport::TimeZone[cohort.time_zone]
      today = zone.today
      cohort.update!(starts_on: today)

      CohortSlot.transaction do
        cohort.cohort_slots.delete_all
        program.program_items.each do |item|
          attributes = { program_item: item, available_on: item.position == 5 ? today + 1 : today }
          if item.exam?
            attributes.merge!(opens_at: zone.local(today.year, today.month, today.day),
                              closes_at: zone.local(today.year, today.month, today.day, 22) + 6.days)
          end
          cohort.cohort_slots.create!(attributes)
        end
      end
    end

    # Every lesson released today and no exam slot (so no exam in this
    # cohort): ticking the three lessons issues a certificate straight away.
    def self.schedule_certificate_cohort(program)
      cohort = program.cohorts.find_or_initialize_by(name: "دفعة تجربة الشهادة")
      today = ActiveSupport::TimeZone[cohort.time_zone].today
      cohort.update!(starts_on: today)

      CohortSlot.transaction do
        cohort.cohort_slots.delete_all
        program.program_items.reject(&:exam?).each do |item|
          cohort.cohort_slots.create!(program_item: item, available_on: today)
        end
      end
    end
  end
end
