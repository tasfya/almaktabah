module LearnerAreaHelper
  def flash_alert_class(type)
    { "notice" => "alert-success", "info" => "alert-info" }.fetch(type.to_s, "alert-error")
  end

  def cohort_time(time, cohort)
    local = time.in_time_zone(cohort.time_zone)
    "#{l(local.to_date, format: :long)} #{l(local, format: :short)}"
  end

  def exam_status(progress, item, scores)
    case progress.exam_state(item)
    when :open then t("programs.exam.open")
    when :not_ready then t("programs.exam.not_ready")
    when :submitted then t("programs.exam.submitted", score: scores[item.exam_id])
    when :missed then t("programs.exam.missed")
    else exam_lock_message(progress, item)
    end
  end

  # A certificate is served only on the site it was issued on, which may not be
  # the site the learner is browsing when the program is shared.
  def learner_certificate_link_target(certificate)
    return certificate_path(certificate) if certificate.domain_id == @domain&.id

    certificate_url(certificate, host: certificate.domain.host, port: nil)
  end

  private

  # :locked means either "the window has not opened yet" or "this exam cannot
  # be taken" (no questions written yet); only the first has a date to show.
  def exam_lock_message(progress, item)
    slot = progress.slot_for(item)
    if item.exam.questions.any? && slot.opens_at > progress.at
      t("programs.exam.opens_on", date: cohort_time(slot.opens_at, progress.enrollment.cohort))
    else
      t("programs.exam.unavailable")
    end
  end
end
