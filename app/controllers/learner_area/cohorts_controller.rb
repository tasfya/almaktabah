module LearnerArea
  class CohortsController < BaseController
    def show
      enrollment = current_enrollment
      # Also catches completions that became due without a tick or a submit,
      # e.g. after an admin hid the last unticked lesson.
      Programs::CertificateIssuer.new(enrollment).call
      load_timeline(enrollment)
      breadcrumb_for(@cohort.program.title, learner_cohort_path(@cohort))
      set_meta_tags(title: "#{@cohort.program.title} — #{@cohort.name}", noindex: true)
    end
  end
end
