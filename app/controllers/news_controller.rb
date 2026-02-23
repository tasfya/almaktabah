# frozen_string_literal: true

class NewsController < ApplicationController
  include TypesenseListable
  before_action :set_news, only: [ :show ]
  before_action :setup_news_breadcrumbs

  def index
    typesense_collection_search("news")
  end

  def show
    description = @news.description.presence || (@news.content.present? ? @news.content.to_plain_text.truncate(MetaTags.config.description_limit) : "")
    image_url = @news.thumbnail.attached? ? url_for(@news.thumbnail) : nil
    set_meta_tags(
      title: @news.title,
      description: description,
      canonical: canonical_url_for(@news),
      og: {
        title: @news.title,
        description: description,
        type: "article",
        url: canonical_url_for(@news),
        image: image_url
      }
    )
  end

  private

  def set_news
    @news = News.friendly
                .includes(scholar: :default_domain)
                .for_domain_id(@domain.id)
                .published
                .find(params[:id])
    redirect_to news_path(@news), status: :moved_permanently if slug_mismatch?(:id, @news)
  rescue ActiveRecord::RecordNotFound
    redirect_to news_index_path, alert: t("messages.news_not_found")
  end

  def setup_news_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.news"), news_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.news"), news_index_path)
      breadcrumb_for(@news.title, news_path(@news))
    end
  end
end
