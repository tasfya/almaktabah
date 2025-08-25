class Avo::Actions::PublishLecture < Avo::BaseAction
  self.name = "Publish lectures"
  self.visible = -> do
    true
  end

  def fields
    field :published_at, as: :date_time, default: -> { Time.current }
  end

  def handle(**args)
    lectures = Lecture.where(id: args[:records])

    lectures.each do |lecture|
      lecture.update!(
        published: true,
        published_at: args[:fields][:published_at]
      )
    end

    succeed "Successfully published #{lectures.count} lecture(s)"
  end
end
