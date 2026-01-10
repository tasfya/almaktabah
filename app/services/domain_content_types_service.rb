# frozen_string_literal: true

class DomainContentTypesService
  CONTENT_COLLECTIONS = TypesenseSearch::Collections::NAMES

  def self.for_domain(domain_id)
    return [] if domain_id.blank?

    new(domain_id).fetch
  end

  def initialize(domain_id)
    @domain_id = domain_id
  end

  def fetch
    response = perform_multi_search
    extract_content_type_counts(response)
  rescue StandardError => e
    Rails.logger.error("DomainContentTypesService error (#{e.class}): #{e.message}")
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
