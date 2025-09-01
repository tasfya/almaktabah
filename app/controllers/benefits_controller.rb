class BenefitsController < ApplicationController
  include Filterable
  before_action :set_benefit, only: [ :show ]
  before_action :setup_benefits_breadcrumbs

  ##
  # Lists published benefits for the current domain.
  #
  # Builds a Ransack search scoped to published benefits for the current domain (ordered by `published_at` descending),
  # paginates the search results (12 items per page) into `@pagy` and `@benefits`, and responds to HTML or JSON.
  # For JSON requests the `@benefits` collection is rendered as JSON.
  def index
    @q = Benefit.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @benefits = pagy(@q.result(distinct: true), limit: 12)

    respond_to do |format|
      format.html
      format.json { render json: @benefits }
    end
  end

  ##
# Renders the show view for a single Benefit.
#
# Relies on the `set_benefit` before_action to load `@benefit`. If the benefit
# cannot be found, `set_benefit` will redirect to the benefits index with an alert.
def show; end

  private

  def set_benefit
    @benefit = Benefit.for_domain_id(@domain.id).published.find(params[:id])
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
