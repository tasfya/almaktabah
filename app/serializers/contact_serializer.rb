class ContactSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :subject, :message, :created_at, :updated_at
end
