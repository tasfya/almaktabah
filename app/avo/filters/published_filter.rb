class Avo::Filters::PublishedFilter < Avo::Filters::SelectFilter
  self.name = "Published status"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "published"
      query.where(published: true)
    when "unpublished"
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
