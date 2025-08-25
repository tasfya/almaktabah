class Avo::Actions::PublishSeries < Avo::BaseAction
  self.name = "Publish series"
  self.visible = -> do
    true
  end

  def fields
    field :published_at, as: :date_time, default: -> { Time.current }
  end

  def handle(**args)
    series = Series.where(id: args[:records])

    series.each do |series_item|
      series_item.update!(
        published: true,
        published_at: args[:fields][:published_at]
      )
    end

    succeed "Successfully published #{series.count} series"
  end
end
