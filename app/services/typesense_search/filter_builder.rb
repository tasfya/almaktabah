# frozen_string_literal: true

module TypesenseSearch
  class FilterBuilder
    def initialize(domain_id: nil, scholars: [], content_types: [])
      @domain_id = domain_id
      @scholars = Array(scholars).map(&:to_s).reject(&:blank?)
      @content_types = Array(content_types).map(&:to_s).map(&:downcase).reject(&:blank?)
    end

    def build
      filters = []
      filters << domain_filter if @domain_id.present?
      filters << scholars_filter if @scholars.present?
      filters.join(" && ")
    end

    def without_scholars
      filters = []
      filters << domain_filter if @domain_id.present?
      filters << content_types_filter if @content_types.present?
      filters.join(" && ")
    end

    private

    def content_types_filter
      return nil if @content_types.empty?

      values = @content_types.map { |t| "`#{sanitize(t)}`" }.join(",")
      "content_type:=[#{values}]"
    end

    def domain_filter
      "domain_ids:=[#{@domain_id}]"
    end

    def scholars_filter
      escaped = @scholars.map { |n| "`#{sanitize(n)}`" }.join(",")
      "scholar_name:=[#{escaped}]"
    end

    def sanitize(value)
      value.delete("`")
    end
  end
end
