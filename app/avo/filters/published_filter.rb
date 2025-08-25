class Avo::Filters::PublishedFilter < Avo::Filters::BooleanFilter
  self.name = "Published status"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    if value["published"] == "1"
      query.where(published: true)
    elsif value["unpublished"] == "1"
      query.where(published: false)
    else
      query
    end
  end

  def options
    {
      "published" => "Published",
      "unpublished" => "Unpublished"
    }
  end
end
