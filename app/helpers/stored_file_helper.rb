module StoredFileHelper
  # A link to a file is only worth rendering when the object is still in the
  # bucket. The answer is cached so a page view costs at most one HEAD per
  # blob; an unreachable service counts as available so a storage outage
  # never hides working downloads.
  def stored_file_available?(attachment)
    return false unless attachment.attached?

    blob = attachment.blob
    Rails.cache.fetch([ "stored_file_available", blob.key ], expires_in: 1.hour) do
      blob.service.exist?(blob.key)
    end
  rescue StandardError => e
    Rails.logger.warn("Could not check #{blob&.key}: #{e.class}: #{e.message}")
    true
  end
end
