module Filterable
  extend ActiveSupport::Concern

  private

  def setup_search_and_pagination(model_class)
    @q = model_class.ransack(params[:q])
    @pagy, @records = pagy(@q.result(distinct: true), limit: 12)
    @records
  end
end
