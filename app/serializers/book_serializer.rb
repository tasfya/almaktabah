class BookSerializer < ActiveModel::Serializer
  attributes :id,
            :title,
            :description,
            :category,
            :published_date,
            :views,
            :downloads,
            :pages,
            :year,
            :file_url,
            :cover_image_url

  belongs_to :author, serializer: ScholarSerializer

  def file_url
    if object.respond_to?(:file) && object.file.present?
          begin
              object.file.url
          rescue ArgumentError => e
              Rails.application.routes.url_helpers.rails_blob_path(object.file, only_path: true) rescue nil
          end
    end
  end

  def cover_image_url
      if object.respond_to?(:cover_image) && object.cover_image.present?
          begin
              object.cover_image.url
          rescue ArgumentError => e
              Rails.application.routes.url_helpers.rails_blob_path(object.cover_image, only_path: true) rescue nil
          end
      end
  end

  def year
    object.published_date.year if object.published_date
  end
end
