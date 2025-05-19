class SeriesSerializer < ActiveModel::Serializer
  attributes :id,
            :title,
            :description,
            :published_date,
            :category,
            :created_at,
            :updated_at,
            :lessons_count

  has_many :lessons

  def lessons_count
    object.lessons.count
  end
end
