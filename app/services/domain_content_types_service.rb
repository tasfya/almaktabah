# frozen_string_literal: true

class DomainContentTypesService
  CACHE_TTL = 10.minutes
  CACHE_KEY_PREFIX = "domain_content_types"

  CONTENT_COLLECTIONS = TypesenseSearchService::CONTENT_COLLECTIONS

  def self.for_domain(domain_id)
    return [] if domain_id.blank?

    Rails.cache.fetch(cache_key(domain_id), expires_in: CACHE_TTL) do
      new(domain_id).fetch
    end
  end

  def self.cache_key(domain_id)
    "#{CACHE_KEY_PREFIX}/#{domain_id}"
  end

  def self.invalidate_cache(domain_id)
    Rails.cache.delete(cache_key(domain_id))
  end

  def initialize(domain_id)
    @domain_id = domain_id
  end

  def fetch
    response = perform_multi_search
    extract_content_type_counts(response)
  rescue Typesense::Error => e
    Rails.logger.error("DomainContentTypesService error: #{e.message}")
    []
  end

  private

  def client
    @client ||= Typesense::Client.new(Typesense.configuration)
  end

  def perform_multi_search
    client.multi_search.perform(
      { searches: build_searches },
      { "q" => "*" }
    )
  end

  def build_searches
    CONTENT_COLLECTIONS.map do |collection|
      {
        "collection" => collection,
        "query_by" => "title",
        "facet_by" => "content_type",
        "filter_by" => "domain_ids:=[#{@domain_id}]",
        "per_page" => 0
      }
    end
  end

  def extract_content_type_counts(response)
    counts = {}

    response["results"].each do |result|
      result["facet_counts"]&.each do |facet|
        next unless facet["field_name"] == "content_type"

        facet["counts"].each do |count|
          type = count["value"]
          counts[type] = (counts[type] || 0) + count["count"]
        end
      end
    end

    counts
      .reject { |_, count| count.zero? }
      .map { |type, count| { type: type, count: count } }
      .sort_by { |ct| -ct[:count] }
  end
end
