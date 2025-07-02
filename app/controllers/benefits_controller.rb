class BenefitsController < ApplicationController
  include Filterable
  before_action :setup_benefits_breadcrumbs

  def index
    @q = Benefit.ransack(params[:q])
    @pagy, @benefits = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Benefit)
  end

  def show
    @benefit = Benefit.find(params[:id])
    @benefit.increment!(:views) if @benefit.respond_to?(:views)
  end

  private

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
