class ProgramsController < ApplicationController
  include TransientBreadcrumbs

  before_action :setup_program_breadcrumbs

  def index
    learner_signed_in? ? no_store : cache_page(duration: 1.day)
    @programs = Program.for_domain_id(@domain.id).published.order(:title).includes(:cohorts)
    @enrolled_program_ids = learner_signed_in? ? current_learner.enrollments.joins(:cohort).pluck("cohorts.program_id").to_set : Set.new
    set_meta_tags(title: t("programs.index.title"), description: t("programs.index.subtitle"))
  end

  # Never edge-cached: the page carries an enroll form (CSRF token) and the
  # signed-in learner's own cohorts.
  def show
    no_store
    @program = find_program
    return render_record_not_found(t("programs.not_found"), programs_path) unless @program

    breadcrumb_for(@program.title, program_path(@program))
    @texts = @program.program_items.book.where(hidden: false).includes(book: :scholar)
    @linkable_book_ids = Book.for_domain_id(@domain.id).published.where(id: @texts.map(&:book_id)).ids.to_set
    @enrolled_cohort_ids = current_learner ? current_learner.enrollments.where(cohort: @program.cohorts).pluck(:cohort_id) : []
    @cohorts = @program.cohorts.order(:starts_on).select { |cohort| @enrolled_cohort_ids.include?(cohort.id) || cohort.enrollment_open? }
    set_meta_tags(title: @program.title, description: @program.description.to_s.truncate(MetaTags.config.description_limit),
                  noindex: !@program.published?)
  end

  private

  def find_program
    scope = Program.for_domain_id(@domain.id)
    scope = scope.published unless current_user&.admin?
    scope.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def setup_program_breadcrumbs
    reset_breadcrumbs
    breadcrumb_for(t("breadcrumbs.programs"), programs_path)
  end
end
