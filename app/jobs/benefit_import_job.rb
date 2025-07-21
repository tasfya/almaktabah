class BenefitImportJob < ApplicationJob
  queue_as :default

  def perform(benefit_data, domain_id: nil)
    return if benefit_data["name"].blank?
    domain = Domain.find_by(id: domain_id) if domain_id

    benefit = Benefit.for_domain_id(domain.id).find_or_initialize_by(title: benefit_data["name"])

    if benefit.new_record?
      benefit.category = benefit_data["series_name"]
      benefit.description = benefit_data["name"]
      benefit.published = true
    end

    begin
      benefit.save!
      Rails.logger.info "✅ Successfully saved benefit: #{benefit.title} (ID: #{benefit.id})"
      benefit.assign_to(domain) if domain

      process_media_files(benefit, benefit_data)

    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "❌ Failed to save benefit: #{benefit.title}"
      Rails.logger.error "Errors: #{benefit.errors.full_messages.join(', ')}"
      raise e
    end
  end

  private

  def process_media_files(benefit, benefit_data)
    if benefit_data["image"].present? && benefit_data["image"].end_with?(".mp3")
      audio_url = benefit_data["image"]
      MediaDownloadJob.perform_later(benefit, audio_url, "audio", "audio/mpeg")
    end
  end
end
