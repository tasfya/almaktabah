class Avo::Actions::PublishBook < Avo::BaseAction
  self.name = "Publish books"
  self.visible = -> do
    true
  end

  def fields
    field :published_at, as: :date_time, default: -> { Time.current }
  end

  def handle(**args)
    books = Book.where(id: args[:records])

    books.each do |book|
      book.update!(
        published: true,
        published_at: args[:fields][:published_at]
      )
    end

    succeed "Successfully published #{books.count} book(s)"
  end
end
