class Avo::Actions::PublishBook < Avo::BaseAction
  self.name = "Publish books"
  self.visible = -> do
    true
  end

  def fields
    field :published_at, as: :date_time, default: -> { Time.current }
  end

  def handle(**args)
    books       = Book.where(id: args[:records])
    published_at = args.dig(:fields, :published_at) || Time.current

    Book.transaction do
      books.each do |book|
        book.update!(
          published:     true,
          published_at: published_at
        )
      end
    end

    succeed "Successfully published #{books.size} book(s)"
  end
end
