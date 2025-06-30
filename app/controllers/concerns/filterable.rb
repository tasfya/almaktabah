module Filterable
  extend ActiveSupport::Concern

  private

  def setup_search_and_pagination(model_class)
    @q = model_class.ransack(params[:q])
    @pagy, @records = pagy(@q.result(distinct: true), limit: 12)
    @records
  end

  def get_categories(model_class)
    model_class.distinct.pluck(:category).compact.sort
  end
end
