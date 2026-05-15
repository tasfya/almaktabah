module PodcastsHelper
  def get_podcast_detail(domain:)
    domain.podcast_details
  end

  def get_podcast_audios(domain_id:)
    lessons = Lesson.published.with_audio.where.not(duration: nil).where.not(published_at: nil)
    lectures = Lecture.published.with_audio.where.not(duration: nil).where.not(published_at: nil)
    lessons = lessons.for_domain_id(domain_id)
    lectures = lectures.for_domain_id(domain_id)

    # Combine and sort by published_at descending (newest first)
    (lectures.to_a + lessons.to_a).sort_by(&:published_at).reverse
  end
end
