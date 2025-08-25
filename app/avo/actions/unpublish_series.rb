class Avo::Actions::UnpublishSeries < Avo::BaseAction
  self.name = "Unpublish series"
  self.visible = -> do
    true
  end

  def handle(**args)
    series = Series.where(id: args[:records])

    series.each do |series_item|
      series_item.update!(published: false)
    end

    succeed "Successfully unpublished #{series.count} series"
  end
end
