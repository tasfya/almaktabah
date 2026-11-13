module Programs
  # The rules for one enrollment, all evaluated at `at` in the cohort's time
  # zone. An item takes part in the cohort only when the cohort has a slot for
  # it and it is not hidden; the same sets feed ticking, the exam gate,
  # percent_complete and the certificate.
  class Progress
    class NotAllowed < StandardError; end

    attr_reader :enrollment, :at

    def initialize(enrollment, at: Time.current)
      @enrollment = enrollment
      @at = at
    end

    def available?(item)
      slot = slot_for(item)
      slot.present? && !item.hidden? && slot.available_on <= today
    end

    def tickable?(item)
      item.lesson? && available?(item) && !ticked?(item)
    end

    def ticked?(item)
      ticked_item_ids.include?(item.id)
    end

    def tick!(item)
      raise NotAllowed unless tickable?(item)

      completion = record_tick(item)
      CertificateIssuer.new(enrollment, at: at).call
      completion
    end

    # A mis-tap can be undone until it could have mattered: not once a
    # certificate exists, nor once an exam that comes after the lesson has an
    # attempt (the tick may have opened it).
    def untickable?(item)
      return false unless item.lesson? && ticked?(item) && slot_for(item)
      return false if enrollment.certificate.present?

      later_exam_ids = exam_items.select { |exam| exam.position > item.position }.map(&:exam_id)
      !enrollment.exam_attempts.exists?(exam_id: later_exam_ids)
    end

    def untick!(item)
      raise NotAllowed unless untickable?(item)

      enrollment.lesson_completions.where(program_item: item).delete_all
      @ticked_item_ids = nil
    end

    # :locked also covers an exam that cannot be taken at all here: no slot
    # in this cohort, hidden, or no questions written yet.
    def exam_state(exam_item)
      return :submitted if submitted_exam_ids.include?(exam_item.exam_id)

      slot = slot_for(exam_item)
      return :locked if slot.nil? || exam_item.hidden? || exam_item.exam.questions.none?
      return :missed if slot.closed?(at)
      return :locked unless slot.open?(at)
      return :not_ready if lesson_items.any? { |lesson| lesson.position < exam_item.position && !ticked?(lesson) }

      :open
    end

    # The cohort's visible items (lessons, books, exams) in position order.
    def items
      @items ||= slots_by_item_id.values.map(&:program_item).reject(&:hidden?).sort_by(&:position)
    end

    def lesson_items
      items.select(&:lesson?)
    end

    def exam_items
      items.select(&:exam?)
    end

    def percent_complete
      lessons = lesson_items
      return 0 if lessons.empty?

      lessons.count { |lesson| ticked?(lesson) } * 100 / lessons.size
    end

    def todays_items
      items.select { |item| slot_for(item).available_on == today }
    end

    def slot_for(item)
      slots_by_item_id[item.id]
    end

    def today
      @today ||= enrollment.cohort.today(at)
    end

    def started?
      today >= enrollment.cohort.starts_on
    end

    # 1-based, counting lessons only, as learners count them ("lesson 14").
    def lesson_number(item)
      @lesson_numbers ||= lesson_items.each.with_index(1).to_h { |lesson, number| [ lesson.id, number ] }
      @lesson_numbers[item.id]
    end

    def submitted_exams_count
      exam_items.count { |exam| submitted_exam_ids.include?(exam.exam_id) }
    end

    def ticked_lessons_count
      lesson_items.count { |lesson| ticked?(lesson) }
    end

    # Released lessons not ticked yet, oldest first.
    def due_lessons
      lesson_items.select { |lesson| tickable?(lesson) }
    end

    def overdue_lessons
      due_lessons.select { |lesson| slot_for(lesson).available_on < today }
    end

    def next_release_on
      lesson_items.map { |lesson| slot_for(lesson).available_on }.select { |date| date > today }.min
    end

    # Exams the learner can or should act on now.
    def pending_exams
      exam_items.select { |exam| %i[open not_ready].include?(exam_state(exam)) }
    end

    def open_exams
      exam_items.select { |exam| exam_state(exam) == :open }
    end

    # Exams whose window has not opened yet.
    def upcoming_exams
      exam_items.select do |exam|
        exam_state(exam) == :locked && exam.exam.questions.any? && slot_for(exam).opens_at > at
      end
    end

    # Exams with no questions yet whose window has not closed: they can't be
    # taken now but may be later.
    def unavailable_exams
      exam_items.select do |exam|
        exam_state(exam) == :locked && exam.exam.questions.none? && !slot_for(exam).closed?(at)
      end
    end

    # Exams that, by the CertificateIssuer rule (every exam needs an attempt at
    # or above the pass mark), keep the certificate out of reach for good:
    # the window closed, or the one attempt scored below the pass mark.
    def blocking_exams
      pass_mark = enrollment.cohort.program.pass_mark
      scores = enrollment.exam_attempts.pluck(:exam_id, :score_percent).to_h
      exam_items.select do |exam|
        score = scores[exam.exam_id]
        next false if score.present? && score >= pass_mark

        exam_state(exam) == :submitted || slot_for(exam).closed?(at)
      end
    end

    def finished?
      started? && due_lessons.empty? && next_release_on.nil? && pending_exams.empty? &&
        upcoming_exams.empty? && unavailable_exams.empty?
    end

    private

    def record_tick(item)
      enrollment.lesson_completions.create!(program_item: item, completed_at: at)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      raise NotAllowed
    ensure
      @ticked_item_ids = nil
    end

    def slots_by_item_id
      @slots_by_item_id ||= enrollment.cohort.cohort_slots.includes(program_item: [ :lesson, :book, { exam: :questions } ]).index_by(&:program_item_id)
    end

    def submitted_exam_ids
      @submitted_exam_ids ||= enrollment.exam_attempts.where.not(submitted_at: nil).pluck(:exam_id).to_set
    end

    def ticked_item_ids
      @ticked_item_ids ||= enrollment.lesson_completions.pluck(:program_item_id).to_set
    end
  end
end
