# frozen_string_literal: true

class SeriesController < ApplicationController
  include TypesenseListable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  def index
    expires_in 1.hour, public: true
    typesense_collection_search("series")
  end

  def show
    expires_in 1.hour, public: true
    @lessons = @series.lessons.for_domain_id(@domain.id).published.ordered_by_lesson_number

    description = @series.description.to_s.truncate(MetaTags.config.description_limit)
    set_meta_tags(
      title: @series.seo_show_title,
      description: description,
      canonical: canonical_url_for(@series),
      og: {
        title: @series.seo_show_title,
        description: description,
        type: "article",
        url: canonical_url_for(@series)
      }
    )
  end

  def legacy_redirect
    series = Series.for_domain_id(@domain.id).published.find(params[:id])
    redirect_to series_path(series.scholar.slug, series), status: :moved_permanently
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end

  private

  def setup_series_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
      breadcrumb_for(@series.title, series_path(@series.scholar, @series))
    end
  end

  def set_series
    @scholar = Scholar.includes(:default_domain).friendly.find(params[:scholar_id])
    @series = @scholar.series.friendly
                      .for_domain_id(@domain.id)
                      .published
                      .find(params[:id])
    if slug_mismatch?(:scholar_id, @scholar) || slug_mismatch?(:id, @series)
      redirect_to series_path(@scholar, @series), status: :moved_permanently
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end
end
