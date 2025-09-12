class BenefitsController < ApplicationController
  include Filterable
  before_action :set_benefit, only: [ :show ]
  before_action :setup_benefits_breadcrumbs

  def index
    @q = Benefit.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @benefits = pagy(@q.result(distinct: true))

    respond_to do |format|
      format.html
      format.json { render json: BenefitSerializer.render(@benefits) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: BenefitSerializer.render(@benefit) }
    end
  end

  private

  def set_benefit
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @benefit = @scholar.benefits.friendly
                       .for_domain_id(@domain.id)
                       .published
                       .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to benefits_path, alert: t("messages.benefit_not_found")
  end

  def setup_benefits_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.benefits"), benefits_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.benefits"), benefits_path)
      breadcrumb_for(@benefit.title, benefit_path(@benefit, scholar_id: @benefit.scholar.to_param))
    end
  end
end
