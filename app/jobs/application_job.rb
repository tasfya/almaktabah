class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  private

  def parse_integer(value)
    Integer(value) rescue nil
  end

  def parse_datetime(value)
    return nil unless value.present?
    return value if value.is_a?(DateTime) || value.is_a?(Time)
    DateTime.parse(value.to_s) rescue nil
  end

  def attach_from_url(record, attachment_name, url, content_type: nil)
    return if url.blank?

    Rails.logger.info "Enqueuing media download for #{attachment_name} from #{url} for record ##{record.id}"
    MediaDownloadJob.perform_now(
      record,
      attachment_name,
      url,
      content_type
    )
  end
end
