class BenefitsController < ApplicationController
  include Filterable
  before_action :set_benefit, only: [ :show ]
  before_action :setup_benefits_breadcrumbs

  def index
    @q = Benefit.ransack(params[:q])
    @pagy, @benefits = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Benefit)
  end

  def show; end

  private

  def set_benefit
    @benefit = Benefit.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to benefits_path, alert: t("messages.benefit_not_found")
  end

  def setup_benefits_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.benefits"), benefits_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.benefits"), benefits_path)
      breadcrumb_for(@benefit.title, benefit_path(@benefit))
    end
  end
end
