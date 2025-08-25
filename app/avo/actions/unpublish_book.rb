class Avo::Actions::UnpublishBook < Avo::BaseAction
  self.name = "Unpublish books"
  self.visible = -> do
    true
  end

  def handle(**args)
    books = Book.where(id: args[:records])

    books.each do |book|
      book.update!(published: false)
    end

    succeed "Successfully unpublished #{books.count} book(s)"
  end
end
