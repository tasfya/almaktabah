module LearnerArea
  class DashboardController < BaseController
    def show
      set_meta_tags(title: t("programs.dashboard.title"), noindex: true)
      @enrollments = domain_enrollments.includes(cohort: :program).order(enrolled_at: :desc)
    end
  end
end
