class NewsSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :content,
             :description,
             :published_at,
             :slug,
             :created_at,
             :updated_at,
             :thumbnail_url

  def description
    object.description.present? ? object.description : object.content.to_s.truncate(150)
  end

  def thumbnail_url
    if object.respond_to?(:thumbnail) && object.thumbnail.present?
      begin
        object.thumbnail.url
      rescue ArgumentError => e
        # Return a relative path instead when URL options aren't set
        Rails.application.routes.url_helpers.rails_blob_path(object.thumbnail, only_path: true) rescue nil
      end
    end
  end
end
