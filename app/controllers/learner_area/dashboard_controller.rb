module LearnerArea
  class DashboardController < BaseController
    def show
      set_meta_tags(title: t("programs.dashboard.title"), noindex: true)
      enrollments = domain_enrollments.includes(:certificate, cohort: :program).order(enrolled_at: :desc)
      # Cohorts being followed first, then those not started yet, then finished ones.
      @progresses = enrollments.map { |enrollment| Programs::Progress.new(enrollment) }
                               .sort_by.with_index { |progress, index| [ dashboard_rank(progress), index ] }
    end

    private

    def dashboard_rank(progress)
      if progress.enrollment.certificate || progress.finished? then 2
      elsif progress.started? then 0
      else 1
      end
    end
  end
end
