# frozen_string_literal: true

class SitemapsController < ApplicationController
  def show
    @articles = Article.for_domain_id(@domain.id).published.recent.includes(:scholar)
    @books = Book.for_domain_id(@domain.id).published.recent.includes(:scholar)
    @lectures = Lecture.for_domain_id(@domain.id).published.recent.includes(:scholar)
    @series = Series.for_domain_id(@domain.id).published.recent.includes(:scholar)
    @fatwas = Fatwa.for_domain_id(@domain.id).published.includes(:scholar)
    @news = News.for_domain_id(@domain.id).published.recent
    @scholars = Scholar.published

    respond_to do |format|
      format.xml
    end
  end
end
