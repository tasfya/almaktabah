module ApplicationHelper
  def format_date(date, format = :long)
    return unless date.present?

    l(date, format: format)
  end
end
