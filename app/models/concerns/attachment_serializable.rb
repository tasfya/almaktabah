module AttachmentSerializable
  extend ActiveSupport::Concern

  def attachment_url(attachment)
    return nil unless attachment.attached?
    Rails.application.routes.url_helpers.rails_blob_url(attachment, only_path: true)
  end
end
