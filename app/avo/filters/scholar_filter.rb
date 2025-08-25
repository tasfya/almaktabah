class Avo::Filters::ScholarFilter < Avo::Filters::BooleanFilter
  self.name = "Scholar filter"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    selected_scholar_ids = value.select { |scholar_id, selected| selected }.keys
    return query if selected_scholar_ids.empty?

    query.where(scholar_id: selected_scholar_ids)
  end

  def options
    Scholar.all.map { |scholar| [ scholar.id, scholar.full_name ] }.to_h
  end
end
