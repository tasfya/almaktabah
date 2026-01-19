# frozen_string_literal: true

class SitemapsController < ApplicationController
  def index
    @sitemap_service = SitemapService.new(@domain)
    @content_pages = @sitemap_service.content_type_pages

    fresh_when(etag: sitemap_index_etag, last_modified: sitemap_index_last_modified)
  end

  def show
    @type = params[:type].to_sym
    @page = (params[:page] || 1).to_i
    @sitemap_service = SitemapService.new(@domain)

    if @page < 1 || @page > @sitemap_service.page_count(@type)
      head :not_found
      return
    end

    @records = @sitemap_service.urls_for(@type, page: @page)

    fresh_when(etag: content_etag, last_modified: @sitemap_service.latest_updated_at(@type))
  end

  private

  def sitemap_index_etag
    @content_pages.map { |cp| "#{cp[:type]}-#{cp[:page]}" }.join("-")
  end

  def sitemap_index_last_modified
    SitemapService::CONTENT_TYPES.keys
      .filter_map { |type| @sitemap_service.latest_updated_at(type) }
      .max || Time.current
  end

  def content_etag
    "#{@type}-#{@page}-#{@sitemap_service.latest_updated_at(@type)&.to_i}"
  end
end
