class Avo::Actions::PublishLesson < Avo::BaseAction
  self.name = "Publish lessons"
  self.visible = -> do
    true
  end

  def fields
    field :published_at, as: :date_time, default: -> { Time.current }
  end

  def handle(**args)
    lessons = Lesson.where(id: args[:records])

    lessons.each do |lesson|
      lesson.update!(
        published: true,
        published_at: args[:fields][:published_at]
      )
    end

    succeed "Successfully published #{lessons.count} lesson(s)"
  end
end
