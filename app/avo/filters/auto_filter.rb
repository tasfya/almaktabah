class Avo::Filters::AutoFilter < Avo::Filters::SelectFilter
  self.name = "Auto filter"
  self.visible = -> do
    true
  end

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "recent"
      query.order(created_at: :desc)
    when "oldest"
      query.order(created_at: :asc)
    when "published"
      query.where(published: true)
    when "unpublished"
      query.where(published: false)
    when "with_media"
      query.joins(:audio_attachment).or(query.joins(:video_attachment))
    when "without_media"
      query.where.missing(:audio_attachment).where.missing(:video_attachment)
    when "alphabetical"
      query.order(:title)
    when "reverse_alphabetical"
      query.order(title: :desc)
    when "most_downloaded"
      query.order(downloads: :desc)
    when "least_downloaded"
      query.order(:downloads)
    else
      query
    end
  end

  def options
    {
      "recent" => "Most Recent",
      "oldest" => "Oldest First",
      "published" => "Published Only",
      "unpublished" => "Unpublished Only",
      "with_media" => "With Media Files",
      "without_media" => "Without Media Files",
      "alphabetical" => "Alphabetical (A-Z)",
      "reverse_alphabetical" => "Alphabetical (Z-A)",
      "most_downloaded" => "Most Downloaded",
      "least_downloaded" => "Least Downloaded"
    }
  end
end
