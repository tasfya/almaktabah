# frozen_string_literal: true

require "ostruct"

class FatwaImportJob < ApplicationJob
  include ApplicationHelper

  queue_as :default

  def perform(row_data, domain_id = nil, line_number = nil)
    Rails.logger.info "Processing fatwa import for line #{line_number}"

    row = ::OpenStruct.new(row_data)

    # Validate domain_id and domain existence
    if domain_id.blank?
      Rails.logger.error "domain_id is blank for fatwa import on line #{line_number}"
      return
    end

    unless Domain.exists?(domain_id)
      Rails.logger.error "Domain with id #{domain_id} does not exist for fatwa import on line #{line_number}"
      return
    end

    domain = Domain.find(domain_id)

    ActiveRecord::Base.transaction do
      # Find or create scholar
      if row_data["scholar_id"]
        scholar = Scholar.find(row_data["scholar_id"])
      elsif row_data["scholar_full_name"].present?
        scholar = find_or_create_scholar_by_full_name(row_data["scholar_full_name"])
      end

      if scholar.nil?
        raise ArgumentError, "Scholar information (scholar_id or scholar_full_name) is required"
      end

      published_at = parse_datetime(row.published_at)

      fatwa = Fatwa.find_or_create_by!(
        title: row.title,
        category: row.category,
        scholar_id: scholar.id,
        source_url: row.source_url,
      ) do |f|
        f.published    = published_at.present?
        f.published_at = published_at
      end

      dirty = fatwa.changed?
      if row.question.present? && fatwa.question&.to_plain_text.to_s.blank?
        fatwa.question = row.question
        dirty = true
      end
      if row.answer.present? && fatwa.answer&.to_plain_text.to_s.blank?
        fatwa.answer = row.answer
        dirty = true
      end
      fatwa.save! if dirty

      fatwa.assign_to(domain)

      # Handle file attachments
      attach_from_url(fatwa, :audio, row.audio_file_url, content_type: "audio/mpeg") if row.audio_file_url.present?

      Rails.logger.info "Successfully created/updated fatwa: #{fatwa.title}"
      fatwa
    end
  rescue => e
    Rails.logger.error "Failed to process fatwa import for line #{line_number}: #{e.message}"
    raise e
  end

  private

  def find_or_create_scholar_by_full_name(full_name)
    return nil if full_name.blank?

    Scholar.find_or_create_by!(full_name: full_name.strip) do |s|
      s.published = true
      s.published_at = Time.current
    end
  end

end
