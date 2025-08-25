class Avo::Actions::UnpublishLesson < Avo::BaseAction
  self.name = "Unpublish lessons"
  self.visible = -> do
    true
  end

  def handle(**args)
    lessons = Lesson.where(id: args[:fields][:records])

    lessons.each do |lesson|
      lesson.update!(published: false)
    end

    succeed "Successfully unpublished #{lessons.count} lesson(s)"
  end
end
