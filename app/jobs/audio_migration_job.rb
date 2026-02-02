class AudioMigrationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(record_type, record_id)
    record = record_type.constantize.find_by(id: record_id)

    unless record
      Rails.logger.warn "#{record_type}##{record_id} not found, skipping migration"
      return
    end

    unless record.respond_to?(:migrate_to_final_audio)
      Rails.logger.error "#{record_type} does not support migrate_to_final_audio"
      return
    end

    unless record.optimized_audio.attached?
      Rails.logger.info "#{record_type}##{record_id} has no optimized_audio, skipping"
      return
    end

    if record.final_audio.attached?
      Rails.logger.info "#{record_type}##{record_id} already has final_audio, skipping"
      return
    end

    if record.migrate_to_final_audio
      Rails.logger.info "✓ Successfully migrated #{record_type}##{record_id}"
    else
      Rails.logger.error "✗ Failed to migrate #{record_type}##{record_id}"
      raise "Migration failed for #{record_type}##{record_id}"
    end
  end
end
