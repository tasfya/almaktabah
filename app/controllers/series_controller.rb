# frozen_string_literal: true

class SeriesController < ApplicationController
  include TypesenseListable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  def index
    typesense_search(content_type: "series")
  end

  def show
    @lessons = @series.lessons.for_domain_id(@domain.id).published.ordered_by_lesson_number
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
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @series = @scholar.series.friendly
                      .for_domain_id(@domain.id)
                      .published
                      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end
end
