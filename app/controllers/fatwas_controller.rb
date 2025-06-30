class FatwasController < ApplicationController
  include Filterable
  before_action :setup_fatwas_breadcrumbs

  def index
    @q = Fatwa.ransack(params[:q])
    @pagy, @fatwas = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Fatwa)

    respond_to do |format|
      format.html
      format.json { render json: @fatwas }
    end
  end

  def show
    @fatwa = Fatwa.find(params[:id])
    @fatwa.increment!(:views) if @fatwa.respond_to?(:views)
  end

  private

  def setup_fatwas_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for("الفتاوى", fatwas_path)
    when "show"
      breadcrumb_for("الفتاوى", fatwas_path)
      # Current fatwa will be added in the view
    end
  end
end
