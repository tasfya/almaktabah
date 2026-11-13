module LearnerArea
  # Opening an exam records nothing; the single attempt is created on submit.
  class ExamsController < BaseController
    before_action :load_exam

    def show
      @state = @progress.exam_state(@item)
      @questions = @exam.questions.includes(:choices) if @state.in?(%i[open submitted])
      @attempt = @enrollment.exam_attempts.includes(:attempt_answers).find_by!(exam: @exam) if @state == :submitted
      prepare_page
    end

    def submit
      # Graded at the request's own time, the one @progress and the rescue read,
      # so a submit cannot be accepted or refused on two different clocks.
      attempt = Programs::ExamGrader.new(@enrollment, @item, at: @progress.at).submit!(answer_params)
      # A stale tab submitting again lands on the answers the first one sent.
      notice = helpers.learner_t("programs.exam.already_submitted") unless attempt.previously_new_record?
      redirect_to learner_cohort_exam_path(@cohort, @exam), notice: notice
    rescue Programs::ExamGrader::NotOpen
      @state = @progress.exam_state(@item)
      return refuse_late if @state == :missed

      alert = @state == :not_ready ? helpers.learner_t("programs.exam.submit_not_ready") : t("programs.exam.closed")
      redirect_to learner_cohort_exam_path(@cohort, @exam), alert: alert
    end

    private

    # The answers arrived after the close: nothing is recorded, but the learner
    # sees what they chose instead of an empty page.
    def refuse_late
      @state = :late
      @questions = @exam.questions.includes(:choices)
      @late_choices = answer_params.to_h { |question_id, choice_id| [ question_id.to_i, choice_id.to_i ] }
      closes_at = helpers.program_deadline(@progress.slot_for(@item).closes_at, @cohort, @progress.today)
      flash.now[:alert] = helpers.learner_t("programs.exam.late", time: closes_at)
      prepare_page
      render :show, status: :unprocessable_content
    end

    def prepare_page
      breadcrumb_for(@cohort.program.title, learner_cohort_path(@cohort))
      breadcrumb_for(@item.display_title, learner_cohort_exam_path(@cohort, @exam))
      set_meta_tags(title: @item.display_title, noindex: true)
    end

    def load_exam
      @enrollment = current_enrollment
      @cohort = @enrollment.cohort
      @progress = Programs::Progress.new(@enrollment)
      @item = @progress.exam_items.find { |item| item.exam_id.to_s == params[:id] }
      raise ActiveRecord::RecordNotFound unless @item

      @exam = @item.exam
    end

    def answer_params
      answers = params[:answers]
      answers.is_a?(ActionController::Parameters) ? answers.permit(*@exam.questions.ids.map(&:to_s)).to_h : {}
    end
  end
end
