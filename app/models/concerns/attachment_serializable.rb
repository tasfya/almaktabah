module AttachmentSerializable
  extend ActiveSupport::Concern

  # TODO Mohamed clean up this code
  def attachment_url(attachment)
    return nil if attachment.nil?
    return nil unless attachment.attached?
    return nil if attachment.blob.new_record?

    service_name = attachment.service.name

    # Use direct S3 URL for better performance and CDN compatibility
    if attachment.service.respond_to?(:url) && service_name == :public_media_hetzner
      attachment.url
    elsif service_name == :public_media_aws
      # Use custom domain for R2/AWS storage
      "https://bucket.3ilm.org/#{attachment.blob.key}"
    else
      # Fallback to Rails blob URL for other storage services
      Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
    end
  end
end
