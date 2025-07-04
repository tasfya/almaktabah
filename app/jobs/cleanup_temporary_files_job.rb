class CleanupTemporaryFilesJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    if File.exist?(file_path)
      FileUtils.rm_f(file_path)
      Rails.logger.info "Successfully cleaned up temporary file: #{file_path}"
    else
      Rails.logger.info "Temporary file not found, skipping cleanup: #{file_path}"
    end
  end
end
