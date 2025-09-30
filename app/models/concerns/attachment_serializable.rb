module AttachmentSerializable
  extend ActiveSupport::Concern

  def attachment_url(attachment)
    return nil unless attachment.attached?
    
    if attachment.service.respond_to?(:url) && attachment.service.name == :public_media_hetzner
      attachment.url
    else
      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end
end
