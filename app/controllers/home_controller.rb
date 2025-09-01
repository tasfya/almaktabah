class HomeController < ApplicationController
  def index
    @series = Series.for_domain_id(@domain.id).published.recent.first
    @top_series = Series.for_domain_id(@domain.id).published.recent.limit(5)
    @top_lectures = Lecture.for_domain_id(@domain.id).published.recent.limit(10)
  end
end
