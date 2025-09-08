class FatwasController < ApplicationController
  include Filterable
  before_action :set_fatwa, only: [ :show ]
  before_action :setup_fatwas_breadcrumbs
  def index
    @q = Fatwa.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    results = @q.result(distinct: true).includes(:scholar, :rich_text_question, :rich_text_answer)
    @pagy, @fatwas = pagy(results)

    respond_to do |format|
      format.html
      format.json { render json: @fatwas }
    end
  end
  def show; end

  private

  def set_fatwa
    @fatwa = Fatwa.friendly
                  .for_domain_id(@domain.id)
                  .published
                  .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to fatwas_path, alert: t("messages.fatwa_not_found")
  end

  def setup_fatwas_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.fatwas"), fatwas_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.fatwas"), fatwas_path)
      breadcrumb_for(@fatwa.title, fatwa_path(@fatwa))
    end
  end
end
