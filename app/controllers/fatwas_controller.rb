class FatwasController < ApplicationController
  include Filterable
  before_action :set_fatwa, only: [ :show ]
  before_action :setup_fatwas_breadcrumbs

  def index
    @q = Fatwa.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @fatwas = pagy(@q.result(distinct: true), limit: 12)
  end

  def show; end

  private

  def set_fatwa
    @fatwa = Fatwa.friendly.for_domain_id(@domain.id).find(params[:id])
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
