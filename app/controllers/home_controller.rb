class HomeController < ApplicationController
  def index
    scope = Series.for_domain_id(@domain.id).published.recent.includes(:scholar)
    @series = scope.first
    @top_series = scope.where.not(id: @series&.id).limit(5)
    @top_lectures = Lecture.for_domain_id(@domain.id).published.recent.includes(:scholar).limit(10)
  end
end
