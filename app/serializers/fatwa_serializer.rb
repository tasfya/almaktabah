class FatwaSerializer < ActiveModel::Serializer
    attributes :id,
            :title,
            :published_date,
            :question,
            :answer,
            :views,
            :category,
            :created_at,
            :updated_at
end
