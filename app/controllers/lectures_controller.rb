# frozen_string_literal: true

class LecturesController < ApplicationController
  include TypesenseListable
  before_action :set_lecture, only: [ :show ]
  before_action :setup_lectures_breadcrumbs

  def index
    typesense_collection_search("lecture")
  end

  def show
    @related_lectures = Lecture.for_domain_id(@domain.id)
                               .published.by_category(@lecture.category)
                               .where.not(id: @lecture.id)
                               .recent
                               .limit(4)

    description = @lecture.description.to_s.truncate(155)
    image_url = @lecture.thumbnail.attached? ? url_for(@lecture.thumbnail) : nil
    og_type = @lecture.video.attached? ? "video.other" : "music.song"
    set_meta_tags(
      title: @lecture.seo_show_title,
      description: description,
      canonical: canonical_url,
      og: {
        title: @lecture.seo_show_title,
        description: description,
        type: og_type,
        url: canonical_url,
        image: image_url
      }
    )
  end

  private

  def setup_lectures_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
      breadcrumb_for(@lecture.title, lecture_path(@lecture, kind: @lecture.kind, scholar_id: @lecture.scholar.to_param))
    end
  end

  def set_lecture
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @lecture = @scholar.lectures.friendly
                       .for_domain_id(@domain.id)
                       .published
                       .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end
end
