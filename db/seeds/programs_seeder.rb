module Seeds
  # A small program for trying the learner pages in development. Relative to
  # today: an exam whose window was missed, two lessons released today, an
  # exam open now, a lesson released tomorrow and an exam that opens in three
  # days. Re-running moves the dates so they stay relative to today.
  class ProgramsSeeder
    TITLE = "برنامج تجريبي: القواعد الأربع"
    QUESTIONS = [
      [ "كم عدد القواعد في رسالة القواعد الأربع؟", [ "أربع", "ثلاث", "خمس" ] ],
      [ "من مؤلف رسالة القواعد الأربع؟", [ "الشيخ محمد بن عبد الوهاب", "ابن تيمية", "ابن القيم" ] ],
      [ "العبادة لا تسمى عبادة إلا مع:", [ "التوحيد", "الصيام", "الصدقة" ] ]
    ].freeze

    # [kind, lesson index or exam title, release offset in days, exam window as [opens, closes] offsets]
    LAYOUT = [
      [ :book, nil, -7 ],
      [ :lesson, 0, -7 ],
      [ :exam, "اختبار فات موعده", -5, [ -5, -3 ] ],
      [ :lesson, 1, 0 ],
      [ :lesson, 2, 0 ],
      [ :exam, "اختبار القواعد الأربع", 0, [ 0, 6 ] ],
      [ :lesson, 3, 1 ],
      [ :exam, "اختبار لم يُفتح بعد", 3, [ 3, 5 ] ]
    ].freeze

    def self.seed(domain:)
      lessons = Lesson.order(:id).limit(4).to_a
      book = Book.order(:id).first
      return puts("⚠️ Skipping the dev program: it needs 4 lessons and a book") if lessons.size < 4 || book.nil?

      program = current_program || build_program(lessons, book)
      if program.program_items.count != LAYOUT.size
        return puts("⚠️ Keeping the dev program as it is: learners are enrolled in an older layout")
      end

      program.update!(published: true, domains: [ domain ])
      schedule(program)
      puts "✅ Dev program: #{program.title}"
    end

    # Rebuilds a program seeded with an older layout, unless learners use it.
    def self.current_program
      program = Program.find_by(title: TITLE)
      return program if program.nil? || program.program_items.count == LAYOUT.size
      return program if Enrollment.joins(:cohort).exists?(cohorts: { program_id: program.id })

      program.destroy!
      nil
    end

    def self.build_program(lessons, book)
      Program.transaction do
        program = Program.create!(title: TITLE, description: "برنامج قصير لتجربة صفحات الطلاب: متن، ودروس، واختبارات، وشهادة.")
        LAYOUT.each.with_index(1) do |(kind, reference, _), position|
          attributes = { position: position, kind: kind }
          case kind
          when :book then attributes[:book] = book
          when :lesson then attributes[:lesson] = lessons[reference]
          when :exam then attributes[:exam] = program.exams.create!(title: reference).tap { |exam| add_questions(exam) }
          end
          program.program_items.create!(attributes)
        end
        program
      end
    end

    def self.add_questions(exam)
      QUESTIONS.each.with_index(1) do |(body, choices), position|
        question = exam.questions.new(position: position, body: body, kind: :single_choice)
        choices.each.with_index(1) { |choice, index| question.choices.new(position: index, body: choice, correct: index == 1) }
        question.save!
      end
    end

    def self.schedule(program)
      cohort = program.cohorts.find_or_initialize_by(name: "الدفعة التجريبية")
      zone = ActiveSupport::TimeZone[cohort.time_zone]
      today = zone.today
      # Enrollment would otherwise close with the missed exam's window.
      cohort.update!(starts_on: today - 7, enrollment_closes_at: zone.local(today.year, today.month, today.day) + 30.days)

      CohortSlot.transaction do
        cohort.cohort_slots.delete_all
        program.program_items.zip(LAYOUT).each do |item, (_, _, release, window)|
          attributes = { program_item: item, available_on: today + release }
          if window
            opens = today + window.first
            closes = today + window.last
            attributes.merge!(opens_at: zone.local(opens.year, opens.month, opens.day),
                              closes_at: zone.local(closes.year, closes.month, closes.day, 22))
          end
          cohort.cohort_slots.create!(attributes)
        end
      end
    end
  end
end
