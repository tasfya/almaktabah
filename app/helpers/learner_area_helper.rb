module LearnerAreaHelper
  LEARNER_FORM_FIELDS = %i[full_name gender email password password_confirmation].freeze

  # Field errors in the order the fields appear on the form.
  def learner_form_errors(resource)
    LEARNER_FORM_FIELDS.flat_map { |attribute| resource.errors.messages_for(attribute) } +
      resource.errors.reject { |error| LEARNER_FORM_FIELDS.include?(error.attribute) }.map(&:full_message)
  end

  def learner_field_aria(resource, attribute, hint: false)
    invalid = resource.errors.include?(attribute)
    ids = []
    ids << "learner_#{attribute}_hint" if hint
    ids << "learner_#{attribute}_error" if invalid
    { invalid: (true if invalid), describedby: ids.join(" ").presence }.compact
  end

  def learner_field_error(resource, attribute)
    messages = resource.errors.messages_for(attribute)
    return if messages.empty?

    tag.p(messages.to_sentence, id: "learner_#{attribute}_error", class: "text-red-700 text-sm mt-1")
  end

  def flash_alert_class(type)
    { "notice" => "alert-success", "info" => "alert-info" }.fetch(type.to_s, "alert-error")
  end

  # Second-person copy addressed to the signed-in learner: uses the "_female"
  # variant of the key when there is one. Only for pages that are never
  # publicly cached.
  def learner_t(key, **options)
    female_key = "#{key}_female"
    key = female_key if current_learner&.female? && I18n.exists?(female_key)
    t(key, **options)
  end

  # Arabic number agreement: explicit forms for 1, 2, 3–10 and 11–99.
  def arabic_count(key, count)
    remainder = count % 100
    form =
      if count == 1 then :one
      elsif count == 2 then :two
      elsif (3..10).cover?(remainder) then :few
      elsif (11..99).cover?(remainder) then :many
      else :other
      end
    t("#{key}.#{form}", count: count)
  end

  # "الأربعاء 2 ديسمبر", with the year only when it isn't the current one.
  def program_date(date, today)
    l(date, format: date.year == today.year ? "%A %-d %B" : "%A %-d %B %Y")
  end

  def program_relative_date(date, today)
    case (date - today).to_i
    when 0 then t("programs.dates.today")
    when -1 then t("programs.dates.yesterday")
    when 1 then t("programs.dates.tomorrow")
    else program_date(date, today)
    end
  end

  # A date and, unless it is midnight, the time, in the cohort's zone.
  def program_datetime(time, cohort, today)
    local = time.in_time_zone(cohort.time_zone)
    date = program_date(local.to_date, today)
    local.seconds_since_midnight.zero? ? date : t("programs.dates.at", date: date, time: l(local, format: :long))
  end

  # A closing time: always with the time, and a midnight close is shown as
  # the end of the previous day, which is the last day it is still open.
  def program_deadline(time, cohort, today)
    local = time.in_time_zone(cohort.time_zone)
    return t("programs.dates.end_of_day", date: program_date(local.to_date - 1, today)) if local.seconds_since_midnight.zero?

    t("programs.dates.at", date: program_date(local.to_date, today), time: l(local, format: :long))
  end

  def exam_window(slot, cohort, today)
    t("programs.exam.window", opens: program_datetime(slot.opens_at, cohort, today),
                              closes: program_deadline(slot.closes_at, cohort, today))
  end

  def cohort_time_zone_name(cohort)
    t("programs.time_zones.#{cohort.time_zone.tr("/", "_")}",
      default: t("programs.time_zones.offset", offset: ActiveSupport::TimeZone[cohort.time_zone].now.formatted_offset))
  end

  def exam_title(item)
    title = item.display_title
    title.start_with?(t("programs.exam.label")) ? title : "#{t("programs.exam.label")}: #{title}"
  end

  # What the learner should do next in this cohort: { text:, item: } where
  # item, when present, is the timeline row to jump to.
  def learner_next_step(progress)
    cohort = progress.enrollment.cohort
    today = progress.today

    unless progress.started?
      return { text: t("programs.next_step.starts", date: program_date(cohort.starts_on, today),
                                                    days: arabic_count("programs.counts.days", (cohort.starts_on - today).to_i)) }
    end

    # An open exam closes for good; late lessons can still be caught up.
    if (exam = progress.open_exams.first)
      closes = program_deadline(progress.slot_for(exam).closes_at, cohort, today)
      return { text: t("programs.next_step.exam_open", title: exam_title(exam), closes: closes), item: exam }
    end

    if (lesson = progress.due_lessons.first)
      lesson_label = t("programs.next_step.lesson", number: progress.lesson_number(lesson), title: lesson.display_title)
      overdue = progress.overdue_lessons.size
      text = overdue.positive? ? "#{arabic_count("programs.counts.overdue", overdue)} — #{lesson_label}" : t("programs.next_step.today", lesson: lesson_label)
      return { text: text, item: lesson }
    end

    if (exam = progress.pending_exams.first)
      closes = program_deadline(progress.slot_for(exam).closes_at, cohort, today)
      return { text: t("programs.next_step.exam_open", title: exam_title(exam), closes: closes), item: exam }
    end

    if (date = progress.next_release_on)
      return { text: t("programs.next_step.done_today", date: program_relative_date(date, today)) }
    end

    if (exam = progress.upcoming_exams.first)
      opens = program_datetime(progress.slot_for(exam).opens_at, cohort, today)
      return { text: t("programs.next_step.exam_upcoming", title: exam_title(exam), opens: opens), item: exam }
    end

    if (exam = progress.unavailable_exams.first)
      return { text: t("programs.next_step.exam_unavailable", title: exam_title(exam)), item: exam }
    end

    if (exam = progress.blocking_exams.first)
      return { text: t("programs.next_step.certificate_blocked", title: exam_title(exam)), item: exam }
    end

    { text: t("programs.next_step.finished") }
  end

  def exam_status(progress, item, scores)
    case progress.exam_state(item)
    when :open then t("programs.exam.open")
    when :not_ready then learner_t("programs.exam.not_ready")
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
      t("programs.exam.opens_on", date: program_datetime(slot.opens_at, progress.enrollment.cohort, progress.today))
    else
      t("programs.exam.unavailable")
    end
  end
end
