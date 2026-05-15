module PodcastsHelper
  def get_podcast_detail(domain:)
    domain.podcast_details
  end

  def get_podcast_audios(domain_id:)
    # Only include items with final_audio (stored on public R2 storage)
    # Use distinct to avoid duplicates from domain assignments
    lessons = Lesson.published.with_final_audio
      .where.not(duration: nil)
      .where.not(published_at: nil)
      .for_domain_id(domain_id)
      .distinct

    lectures = Lecture.published.with_final_audio
      .where.not(duration: nil)
      .where.not(published_at: nil)
      .where.not(kind: :benefit)
      .for_domain_id(domain_id)
      .distinct

    # Combine and sort by published_at descending (newest first)
    (lectures.to_a + lessons.to_a).sort_by(&:published_at).reverse
  end
end
