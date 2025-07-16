# frozen_string_literal: true

class MediaDownloadJob < ApplicationJob
  queue_as :default

  def perform(record, attachment_name, url, content_type)
    attach_from_url(record, attachment_name, url, content_type: content_type)
  rescue => e
    Rails.logger.error "MediaDownloadJob failed: #{e.message}"
    raise
  end

  private

  def attach_from_url(record, attachment_name, url, content_type: nil)
    return if url.blank?

    attachment_name = attachment_name.to_s
    tempfile = Tempfile.new([ "import_", File.extname(url) ], binmode: true)
    Rails.logger.info "Downloading #{attachment_name} from #{url} for record ##{record.id}"

    begin
      response = HTTParty.get(
        url,
        headers: { "User-Agent" => "Ruby/MediaDownloadJob" },
        timeout: 10,
        follow_redirects: true
      )

      unless response.success?
        raise "Download failed: #{response.code} #{response.message}"
      end

      tempfile.write(response.body)
      tempfile.rewind

      record.send(attachment_name).attach(
        io: tempfile,
        filename: File.basename(url, ".*").presence || "file_#{Time.current.to_i}",
        content_type: content_type
      )

      Rails.logger.info "Successfully attached #{attachment_name} to #{record.class}##{record.id}"
    rescue => e
      Rails.logger.error "Attachment error for #{attachment_name}: #{e.message}"
      raise
    ensure
      tempfile.close!
    end
  end
end
