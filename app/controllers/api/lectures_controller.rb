# frozen_string_literal: true

module Api
  class LecturesController < BaseController
    def pending_downloads
      lectures = Lecture.with_youtube_url_missing_video
                        .select(:id, :title, :youtube_url)
      lectures = lectures.limit(params[:limit]) if params[:limit].present?

      render json: {
        lectures: lectures.map { |l| { id: l.id, title: l.title, youtube_url: l.youtube_url } },
        count: lectures.size
      }
    end

    def upload_video
      lecture = Lecture.find(params[:id])

      unless params[:video].present?
        return render json: { error: "No video file provided" }, status: :unprocessable_entity
      end

      lecture.video.purge if lecture.video.attached?
      lecture.video.attach(params[:video])

      if params[:thumbnail].present?
        lecture.thumbnail.purge if lecture.thumbnail.attached?
        lecture.thumbnail.attach(params[:thumbnail])
      end

      if lecture.save
        render json: { success: true, lecture_id: lecture.id, video_attached: lecture.video.attached? }
      else
        render json: { error: lecture.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
