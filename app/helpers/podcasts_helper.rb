module PodcastsHelper
  def get_podcast_detail(domain_id: nil, scholar_id: nil)
    # this is hardcoded might be a configuration in the future
    {
      website_url: "https://mohammed-ramzan.com/",
      title: "محمد بن رمزان الهاجري",
      author: "محمد بن رمزان الهاجري",
      description: "دروس و محاضرات فضيلة الشيخ محمد بن رمزان الهاجري",
      art_work: "https://suhayimi.hachimy.com/assets/logo-4f3e7f2e.png"
    }
  end

  def get_podcast_audios(domain_id:)
    lessons = Lesson.published.with_audio.where.not(duration: nil)
    lectures = Lecture.published.with_audio.where.not(duration: nil)
    lessons = lessons.for_domain_id(domain_id)
    lectures = lectures.for_domain_id(domain_id)
    lectures + lessons
  end
end
