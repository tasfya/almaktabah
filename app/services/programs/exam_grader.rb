module Programs
  # Records the learner's single attempt at an exam and scores it. A submit
  # after the attempt exists, from another tab or a racing request, returns
  # the stored attempt unchanged.
  class ExamGrader
    class NotOpen < StandardError; end

    def initialize(enrollment, exam_item, at: Time.current)
      @enrollment = enrollment
      @exam_item = exam_item
      @at = at
    end

    def submit!(answers)
      existing = ExamAttempt.find_by(enrollment: @enrollment, exam_id: @exam_item.exam_id)
      return existing if existing
      raise NotOpen unless Progress.new(@enrollment, at: @at).exam_state(@exam_item) == :open

      attempt = record_attempt(answers)
      CertificateIssuer.new(@enrollment, at: @at).call if attempt.previously_new_record?
      attempt
    end

    private

    def record_attempt(answers)
      create_attempt(answers)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      ExamAttempt.where(enrollment: @enrollment, exam_id: @exam_item.exam_id).take || raise
    end

    def create_attempt(answers)
      questions = @exam_item.exam.questions.includes(:choices).to_a
      raise NotOpen if questions.empty?

      chosen = valid_choices(questions, answers)
      correct = chosen.count(&:correct?)

      ExamAttempt.transaction do
        attempt = ExamAttempt.create!(enrollment: @enrollment, exam: @exam_item.exam, started_at: @at, submitted_at: @at,
                                      score_percent: (correct * 100.0 / questions.size).round)
        chosen.each { |choice| attempt.attempt_answers.create!(question_id: choice.question_id, choice: choice) }
        attempt
      end
    end

    def valid_choices(questions, answers)
      choice_ids = answers.to_h.transform_keys(&:to_i).transform_values(&:to_i)
      questions.filter_map do |question|
        question.choices.find { |choice| choice.id == choice_ids[question.id] }
      end
    end
  end
end
