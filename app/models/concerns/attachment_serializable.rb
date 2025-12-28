module AttachmentSerializable
  extend ActiveSupport::Concern

  def attachment_url(attachment)
    return nil unless attachment.attached?
    return nil if attachment.blob.new_record?

    # Use direct S3 URL for better performance and CDN compatibility
    if attachment.service.respond_to?(:url) && attachment.service.name == :public_media_hetzner
      attachment.url
    else
      # Fallback to Rails blob URL for other storage services
      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end
end
