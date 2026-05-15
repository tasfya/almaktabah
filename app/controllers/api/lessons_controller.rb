# frozen_string_literal: true

module Api
  class LessonsController < BaseController
    def pending_downloads
      lessons = Lesson.with_youtube_url_missing_video
                      .select(:id, :title, :youtube_url)
      lessons = lessons.limit(params[:limit]) if params[:limit].present?

      render json: {
        lessons: lessons.map { |l| { id: l.id, title: l.title, youtube_url: l.youtube_url } },
        count: lessons.size
      }
    end

    def upload_video
      lesson = Lesson.find(params[:id])

      unless params[:video].present?
        return render json: { error: "No video file provided" }, status: :unprocessable_entity
      end

      lesson.video.purge if lesson.video.attached?
      lesson.video.attach(params[:video])

      if params[:thumbnail].present?
        lesson.thumbnail.purge if lesson.thumbnail.attached?
        lesson.thumbnail.attach(params[:thumbnail])
      end

      if lesson.save
        render json: { success: true, lesson_id: lesson.id, video_attached: lesson.video.attached? }
      else
        render json: { error: lesson.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
