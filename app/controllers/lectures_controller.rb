# frozen_string_literal: true

class LecturesController < ApplicationController
  include TypesenseListable
  before_action :set_lecture, only: [ :show ]
  before_action :setup_lectures_breadcrumbs

  def index
    expires_in 1.hour, public: true
    typesense_collection_search("lecture")
  end

  def show
    expires_in 1.hour, public: true
    @related_lectures = Lecture.for_domain_id(@domain.id)
                               .published.by_category(@lecture.category)
                               .where.not(id: @lecture.id)
                               .recent
                               .limit(4)

    description = @lecture.description.to_s.truncate(MetaTags.config.description_limit)
    image_url = @lecture.thumbnail.attached? ? url_for(@lecture.thumbnail) : nil
    og_type = @lecture.video.attached? ? "video.other" : "music.song"
    set_meta_tags(
      title: @lecture.seo_show_title,
      description: description,
      canonical: canonical_url_for(@lecture),
      og: {
        title: @lecture.seo_show_title,
        description: description,
        type: og_type,
        url: canonical_url_for(@lecture),
        image: image_url
      }
    )
  end

  def legacy_redirect
    lecture = Lecture.for_domain_id(@domain.id).published.find(params[:id])
    redirect_to lecture_path(lecture.scholar.slug, lecture, kind: lecture.kind_for_url), status: :moved_permanently
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end

  private

  def setup_lectures_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
      breadcrumb_for(@lecture.title, lecture_path(@lecture, kind: @lecture.kind_for_url, scholar_id: @lecture.scholar.to_param))
    end
  end

  def set_lecture
    @scholar = Scholar.includes(:default_domain).friendly.find(params[:scholar_id])
    @lecture = @scholar.lectures.friendly
                       .for_domain_id(@domain.id)
                       .published
                       .find(params[:id])
    if slug_mismatch?(:scholar_id, @scholar) || slug_mismatch?(:id, @lecture)
      redirect_to lecture_path(@scholar, @lecture, kind: @lecture.kind_for_url), status: :moved_permanently
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end
end
