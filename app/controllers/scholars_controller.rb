class ScholarsController < ApplicationController
  include Filterable
  before_action :set_scholar, only: [ :show ]
  before_action :setup_scholars_breadcrumbs

  def index
    @q = Scholar.published.order(:first_name).ransack(params[:q])
    @pagy, @scholars = pagy(@q.result(distinct: true))

    respond_to do |format|
      format.html
      format.json { render json: @scholars }
    end
  end

  def show
  end

  private

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
    @scholar = Scholar.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to scholars_path, alert: t("messages.scholar_not_found")
  end
end
