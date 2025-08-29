class Avo::Filters::CategoryFilter < Avo::Filters::SelectFilter
  self.name = "Category"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    query.where(category: value)
  end

  def options
    # Get categories from all relevant models
    lecture_categories = Lecture.distinct.pluck(:category).compact
    book_categories = Book.distinct.pluck(:category).compact
    series_categories = Series.distinct.pluck(:category).compact

    # Combine all categories and sort
    all_categories = (lecture_categories + book_categories + series_categories).uniq.sort

    all_categories.map { |category| [ category, category ] }.to_h
  end
end
