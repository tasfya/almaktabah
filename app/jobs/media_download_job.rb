require "open-uri"

class MediaDownloadJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3

  BASE_URL = "https://mohammed-ramzan.com"

  def perform(model, media_url, attachment_name, content_type, options = {})
    begin
      attach_media_from_url(model, media_url, attachment_name, content_type, options)
      Rails.logger.info "✅ Successfully attached #{attachment_name}"
    rescue => e
      Rails.logger.error "❌ Error processing #{attachment_name} #{e.message}"
      raise e
    end
  end

  private

  def attach_media_from_url(model, url, attachment_name, content_type, options = {})
    full_url = build_full_url(url, options[:base_url])
    filename = options[:filename] || File.basename(url)

    URI.open(full_url) do |file|
      model.public_send(attachment_name).attach(
        io: file,
        filename: filename,
        content_type: content_type
      )
    end
  end

  def build_full_url(url, base_url = nil)
    return url if url.start_with?("http")

    base = base_url || BASE_URL
    "#{base}/#{url}"
  end

  def model_display_name(model)
    return model.title if model.respond_to?(:title)
    return model.name if model.respond_to?(:name)
    model.id.to_s
  end
end
