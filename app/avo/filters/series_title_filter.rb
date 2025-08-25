class Avo::Filters::SeriesTitleFilter < Avo::Filters::SelectFilter
  self.name = "Series"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    query.joins(:series).where(series: { title: value })
  end

  def options
    # Get all series titles that have lessons
    series_titles = Series.joins(:lessons)
                         .distinct
                         .pluck(:title)
                         .compact
                         .sort

    series_titles.map { |title| [ title, title ] }.to_h
  end
end
