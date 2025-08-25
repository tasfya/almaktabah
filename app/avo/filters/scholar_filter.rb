class Avo::Filters::ScholarFilter < Avo::Filters::BooleanFilter
  self.name = "Scholar filter"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    selected_scholar_ids = value.select { |scholar_id, selected| selected }.keys
    return query if selected_scholar_ids.empty?

    # Handle different resource types
    if query.model == Lesson
      # For lessons, filter through series
      query.joins(:series).where(series: { scholar_id: selected_scholar_ids })
    elsif query.model == Series
      # For series, filter directly
      query.where(scholar_id: selected_scholar_ids)
    elsif query.model == Lecture
      # For lectures, filter directly
      query.where(scholar_id: selected_scholar_ids)
    else
      # For other models, try direct scholar_id if it exists
      if query.model.column_names.include?("scholar_id")
        query.where(scholar_id: selected_scholar_ids)
      else
        query
      end
    end
  end

  def options
    Scholar.all.map { |scholar| [ scholar.id, scholar.full_name ] }.to_h
  end
end
