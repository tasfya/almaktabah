# frozen_string_literal: true

class ArticlesController < ApplicationController
  include TypesenseListable
  before_action :set_article, only: [ :show ]
  before_action :setup_articles_breadcrumbs

  def index
    typesense_collection_search("article")
  end

  def show
  end

  private

  def setup_articles_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.articles"), articles_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.articles"), articles_path)
      breadcrumb_for(@article.title, article_path(@scholar, @article))
    end
  end

  def set_article
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @article = @scholar.articles.friendly
                       .for_domain_id(@domain.id)
                       .published
                       .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: t("messages.article_not_found")
  end
end
