module LearnerArea
  # Opening an exam records nothing; the single attempt is created on submit.
  class ExamsController < BaseController
    before_action :load_exam

    def show
      @state = @progress.exam_state(@item)
      @questions = @exam.questions.includes(:choices) if @state.in?(%i[open submitted])
      @attempt = @enrollment.exam_attempts.includes(:attempt_answers).find_by!(exam: @exam) if @state == :submitted
      breadcrumb_for(@cohort.program.title, learner_cohort_path(@cohort))
      breadcrumb_for(@item.display_title, learner_cohort_exam_path(@cohort, @exam))
      set_meta_tags(title: @item.display_title, noindex: true)
    end

    def submit
      Programs::ExamGrader.new(@enrollment, @item).submit!(answer_params)
      redirect_to learner_cohort_exam_path(@cohort, @exam)
    rescue Programs::ExamGrader::NotOpen
      redirect_to learner_cohort_exam_path(@cohort, @exam), alert: t("programs.exam.closed")
    end

    private

    def load_exam
      @enrollment = current_enrollment
      @cohort = @enrollment.cohort
      @progress = Programs::Progress.new(@enrollment)
      @item = @progress.exam_items.find { |item| item.exam_id.to_s == params[:id] }
      raise ActiveRecord::RecordNotFound unless @item

      @exam = @item.exam
    end

    def answer_params
      params.fetch(:answers, {}).permit(*@exam.questions.ids.map(&:to_s)).to_h
    end
  end
end
