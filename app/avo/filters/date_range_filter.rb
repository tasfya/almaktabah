class Avo::Filters::DateRangeFilter < Avo::Filters::SelectFilter
  self.name = "Date range"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "today"
      query.where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
    when "yesterday"
      query.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day)
    when "this_week"
      query.where(created_at: Time.current.beginning_of_week..Time.current.end_of_week)
    when "last_week"
      query.where(created_at: 1.week.ago.beginning_of_week..1.week.ago.end_of_week)
    when "this_month"
      query.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
    when "last_month"
      query.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month)
    when "this_year"
      query.where(created_at: Time.current.beginning_of_year..Time.current.end_of_year)
    when "last_year"
      query.where(created_at: 1.year.ago.beginning_of_year..1.year.ago.end_of_year)
    when "last_7_days"
      query.where(created_at: 7.days.ago..Time.current)
    when "last_30_days"
      query.where(created_at: 30.days.ago..Time.current)
    when "last_90_days"
      query.where(created_at: 90.days.ago..Time.current)
    else
      query
    end
  end

  def options
    {
      "today" => "Today",
      "yesterday" => "Yesterday",
      "this_week" => "This Week",
      "last_week" => "Last Week",
      "this_month" => "This Month",
      "last_month" => "Last Month",
      "this_year" => "This Year",
      "last_year" => "Last Year",
      "last_7_days" => "Last 7 Days",
      "last_30_days" => "Last 30 Days",
      "last_90_days" => "Last 90 Days"
    }
  end
end
