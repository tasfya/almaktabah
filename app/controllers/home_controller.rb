# frozen_string_literal: true

class HomeController < ApplicationController
  SHELF_PER_PAGE = 6
  RECENT_MIXED_LIMIT = 6
  SPOTLIGHT_LIMIT = 8

  def index
    cache_page(duration: 1.day)

    @query = params[:q].is_a?(String) ? params[:q].strip.presence : nil
    @search_filters = { scholars: params[:scholars], content_types: params[:content_types] }
    @all_content_types = TypesenseSearch::Collections::NAMES

    if search_or_filter_active?
      render_search_results
    else
      render_curated_home
    end
  end

  private

  def search_or_filter_active?
    @query.present? || params[:scholars].present? || params[:content_types].present?
  end

  def render_search_results
    result = TypesenseSearch::MixedSearchService.new(
      query: @query,
      domain_id: @domain&.id,
      content_types: params[:content_types],
      scholars: params[:scholars],
      page: params[:page],
      per_page: 21
    ).call

    @results = result.grouped_hits
    @facets = result.facets
    @total_results = result.total_found
    @page = result.page
    @per_page = result.per_page
    @total_pages = result.total_pages

    set_noindex_meta_tags
    render "search/index"
  end

  def render_curated_home
    result = TypesenseSearch::HomeBrowseService.new(
      domain_id: @domain&.id,
      per_page: SHELF_PER_PAGE
    ).call

    @grouped = result.grouped_hits
    @facets = result.facets
    @total_results = result.total_found

    @recent_mixed = build_recent_mixed(@grouped)
    @spotlight_scholars = build_spotlight_scholars(@domain&.id)
    @content_counts = build_content_counts(@domain&.id)
  end

  def build_recent_mixed(grouped)
    grouped.values.flatten.sort_by { |hit| -hit.created_at_ts.to_i }.first(RECENT_MIXED_LIMIT)
  end

  def build_spotlight_scholars(domain_id)
    return [] if domain_id.blank?

    Rails.cache.fetch([ "spotlight_scholars_v1", domain_id ], expires_in: 6.hours) do
      counts = Lecture.published.for_domain_id(domain_id).group(:scholar_id).count
      top = counts.sort_by { |_, c| -c }.first(SPOTLIGHT_LIMIT)
      scholars = Scholar.published.where(id: top.map(&:first)).index_by(&:id)
      top.filter_map { |sid, c| { scholar: scholars[sid], count: c } if scholars[sid] }
    end
  end

  def build_content_counts(domain_id)
    DomainContentTypesService.for_domain(domain_id).each_with_object({}) { |row, h| h[row[:type]] = row[:count] }
  end
end
