# Configure ActiveModel::Serializer to use the :json_api adapter
ActiveModelSerializers.config.adapter = :json_api
ActiveModelSerializers.config.key_transform = :underscore
