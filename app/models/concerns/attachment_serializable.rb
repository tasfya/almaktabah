module AttachmentSerializable
  extend ActiveSupport::Concern

  def attachment_url(attachment)
    return nil unless attachment.attached?
    url_for_storage(attachment)
  end

  def variant_url(variant)
    return nil unless variant
    url_for_storage(variant)
  end

  private

  def url_for_storage(resource)
    # Use direct S3 URL for better performance and CDN compatibility
    if resource.service.respond_to?(:url) && resource.service.name == :public_media_hetzner
      resource.url
    else
      # Fallback to Rails blob URL for other storage services
      Rails.application.routes.url_helpers.rails_blob_url(resource, only_path: true)
    end
  end
end
