class ScholarsController < ApplicationController
  include Filterable
  before_action :set_scholar, only: [ :show ]
  before_action :setup_scholars_breadcrumbs
  before_action :check_scholars_listing_allowed, only: [ :index ]

  def index
    @q = @domain.filtered_scholars.published.order(:first_name, :last_name).ransack(params[:q])
    @pagy, @scholars = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
    @lectures = Lecture.for_domain_id(@domain.id)
                      .published
                      .where(scholar: @scholar)
                      .order(published_at: :desc)
                      .limit(6)

    @series = Series.for_domain_id(@domain.id)
                   .published
                   .where(scholar: @scholar)
                   .order(published_at: :desc)
                   .limit(6)
  end

  private

  def check_scholars_listing_allowed
    unless @domain.allow_scholars_listing?
      # If it's a scholar-specific domain, redirect to the scholar's page
      if @domain.assigned_scholar
        redirect_to scholar_path(@domain.assigned_scholar)
      else
        redirect_to root_path, alert: t("messages.scholars_listing_not_allowed")
      end
    end
  end

  def setup_scholars_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.scholars"), scholars_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.scholars"), scholars_path)
      breadcrumb_for(@scholar.name, scholar_path(@scholar))
    end
  end

  def set_scholar
    @scholar = @domain.filtered_scholars.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    if @domain.scholar_specific?
      # For scholar-specific domains, redirect to root since there's only one scholar
      redirect_to root_path, alert: t("messages.scholar_not_found")
    else
      # For general domains, redirect to scholars listing
      redirect_to scholars_path, alert: t("messages.scholar_not_found")
    end
  end
end
