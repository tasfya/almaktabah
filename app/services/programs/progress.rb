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

      completion = enrollment.lesson_completions.create!(program_item: item, completed_at: at)
      @ticked_item_ids = nil
      completion
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      @ticked_item_ids = nil
      raise NotAllowed
    end

    # :locked also covers an exam that cannot be taken at all here: no slot
    # in this cohort, hidden, or no questions written yet.
    def exam_state(exam_item)
      return :submitted if submitted_exam_ids.include?(exam_item.exam_id)

      slot = slot_for(exam_item)
      return :locked if slot.nil? || exam_item.hidden? || !exam_item.exam.questions.exists?
      return :missed if slot.closed?(at)
      return :locked unless slot.open?(at)
      return :not_ready if lesson_items.any? { |lesson| lesson.position < exam_item.position && !ticked?(lesson) }

      :open
    end

    def lesson_items
      scheduled_items.select(&:lesson?)
    end

    def exam_items
      scheduled_items.select(&:exam?)
    end

    def percent_complete
      lessons = lesson_items
      return 0 if lessons.empty?

      lessons.count { |lesson| ticked?(lesson) } * 100 / lessons.size
    end

    def todays_items
      scheduled_items.select { |item| slot_for(item).available_on == today }
    end

    def slot_for(item)
      slots_by_item_id[item.id]
    end

    private

    def today
      @today ||= enrollment.cohort.today(at)
    end

    def slots_by_item_id
      @slots_by_item_id ||= enrollment.cohort.cohort_slots.includes(:program_item).index_by(&:program_item_id)
    end

    def scheduled_items
      @scheduled_items ||= slots_by_item_id.values.map(&:program_item).reject(&:hidden?).sort_by(&:position)
    end

    def submitted_exam_ids
      @submitted_exam_ids ||= enrollment.exam_attempts.where.not(submitted_at: nil).pluck(:exam_id).to_set
    end

    def ticked_item_ids
      @ticked_item_ids ||= enrollment.lesson_completions.pluck(:program_item_id).to_set
    end
  end
end
