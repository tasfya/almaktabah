# frozen_string_literal: true

require "ostruct"

class ArticleImportJob < ApplicationJob
  include ApplicationHelper

  queue_as :default

  def perform(row_data, domain_id = nil, line_number = nil)
    Rails.logger.info "Processing article import for line #{line_number}"

    row = ::OpenStruct.new(row_data)

    if domain_id.blank?
      Rails.logger.error "domain_id is blank for article import on line #{line_number}"
      return
    end

    unless Domain.exists?(domain_id)
      Rails.logger.error "Domain with id #{domain_id} does not exist for article import on line #{line_number}"
      return
    end

    domain = Domain.find(domain_id)

    ActiveRecord::Base.transaction do
      if row_data["scholar_id"]
        scholar = Scholar.find(row_data["scholar_id"])
      elsif row_data["scholar_full_name"].present?
        scholar = find_or_create_scholar_by_full_name(row_data["scholar_full_name"])
      end

      if scholar.nil?
        raise ArgumentError, "Scholar information (scholar_id or scholar_full_name) is required"
      end

      published_at = parse_datetime(row.published_at)

      article = Article.find_or_create_by!(
        title: row.title,
        category: row.category,
        author_id: scholar.id,
      ) do |a|
        a.published    = published_at.present?
        a.published_at = published_at
      end

      dirty = article.changed?
      if row.content.present? && article.content&.to_plain_text.to_s.blank?
        article.content = row.content
        dirty = true
      end
      article.save! if dirty

      article.assign_to(domain)

      Rails.logger.info "Successfully created/updated article: #{article.title}"
      article
    end
  rescue => e
    Rails.logger.error "Failed to process article import for line #{line_number}: #{e.message}"
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
