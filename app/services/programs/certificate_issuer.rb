module Programs
  # Issues the enrollment's certificate once every cohort lesson is ticked and
  # every cohort exam has an attempt at or above the program's pass mark. It
  # decides on stored ticks and scores only, so a missed exam or one with no
  # questions yet blocks it simply by having no attempt.
  class CertificateIssuer
    # Printed and typed back by hand: no 0/O or 1/I look-alikes.
    NUMBER_ALPHABET = (("A".."Z").to_a + ("2".."9").to_a - %w[O I]).freeze

    def initialize(enrollment, at: Time.current)
      @enrollment = enrollment
      @at = at
    end

    def call
      existing = Certificate.find_by(enrollment: @enrollment)
      return existing if existing
      return unless complete?

      issue
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      Certificate.where(enrollment: @enrollment).take || raise
    end

    private

    def complete?
      progress = Progress.new(@enrollment, at: @at)
      lessons = progress.lesson_items
      exams = progress.exam_items
      return false if lessons.empty? && exams.empty?

      ticked = @enrollment.lesson_completions.pluck(:program_item_id).to_set
      scores = @enrollment.exam_attempts.pluck(:exam_id, :score_percent).to_h
      pass_mark = @enrollment.cohort.program.pass_mark

      lessons.all? { |lesson| ticked.include?(lesson.id) } &&
        exams.all? { |exam| scores[exam.exam_id].present? && scores[exam.exam_id] >= pass_mark }
    end

    def issue
      learner = @enrollment.learner
      Certificate.transaction do
        certificate = Certificate.create!(
          enrollment: @enrollment, domain_id: @enrollment.domain_id, issued_at: @at,
          number: "#{@enrollment.cohort_id}-#{SecureRandom.alphanumeric(8, chars: NUMBER_ALPHABET)}",
          full_name_snapshot: learner.full_name, gender_snapshot: learner.gender
        )
        @enrollment.update!(completed_at: @at)
        certificate
      end
    end
  end
end
