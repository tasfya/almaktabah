class LessonSerializer < ActiveModel::Serializer
    attributes :id,
            :title,
            :description,
            :duration,
            :published_date,
            :category,
            :content,
            :created_at,
            :updated_at,
            :thumbnail_url,
            :audio_url,
            :series_id,
            :series_title

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

    def audio_url
        if object.respond_to?(:audio) && object.audio.present?
            begin
                object.audio.url
            rescue ArgumentError => e
                # Return a relative path instead when URL options aren't set
                Rails.application.routes.url_helpers.rails_blob_path(object.audio, only_path: true) rescue nil
            end
        end
    end
    
    def series_id
        object.series&.id
    end
    
    def series_title
        object.series&.title
    end
end
