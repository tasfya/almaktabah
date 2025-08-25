class Avo::Actions::UnpublishLecture < Avo::BaseAction
  self.name = "Unpublish lectures"
  self.visible = -> do
    true
  end

  def handle(**args)
    lectures = Lecture.where(id: args[:records])

    lectures.each do |lecture|
      lecture.update!(published: false)
    end

    succeed "Successfully unpublished #{lectures.count} lecture(s)"
  end
end
