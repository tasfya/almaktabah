class LectureSerializer < ActiveModel::Serializer
    attributes :id,
              :title,
              :description,
              :category,
              :published_date,
              :duration,
              :views,
              :thumbnail_url,
              :audio_url,
  
    def thumbnail_url
        if object.respond_to?(:thumbnail) && object.thumbnail.present?
            begin
                object.thumbnail.url
            rescue ArgumentError => e
                Rails.application.routes.url_helpers.rails_blob_path(object.thumbnail, only_path: true) rescue nil
            end
        end
    end
    def audio_url
        if object.respond_to?(:audio) && object.audio.present?
            begin
                object.audio.url
            rescue ArgumentError => e
                Rails.application.routes.url_helpers.rails_blob_path(object.audio, only_path: true) rescue nil
            end
        end
    end
  end
  