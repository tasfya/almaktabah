class AddYoutubeUrlToLessonsAndLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lessons, :youtube_url, :string
    add_column :lectures, :youtube_url, :string
    # Helper method to detect YouTube URLs
    def youtube_url?(url)
      return false unless url.present?
      url.include?('youtube.com') || url.include?('youtu.be')
    end

    youtube_lessons = []
    youtube_lectures = []

    Lesson.find_each do |lesson|
      if lesson.video_url.present? && youtube_url?(lesson.video_url)
        lesson.update_column(:youtube_url, lesson.video_url)
        lesson.update_column(:video_url, nil)
        youtube_lessons << lesson
        puts "Moved YouTube URL for lesson: #{lesson.title}"
      end
    end

    Lecture.find_each do |lecture|
      if lecture.video_url.present? && youtube_url?(lecture.video_url)
        lecture.update_column(:youtube_url, lecture.video_url)
        lecture.update_column(:video_url, nil)
        youtube_lectures << lecture
        puts "Moved YouTube URL for lecture: #{lecture.title}"
      end
    end

    puts "\nQueuing YouTube download jobs..."

    youtube_lessons.each do |lesson|
      begin
        YoutubeDownloadJob.perform_later('Lesson', lesson.id, 'video')
        puts "Queued video download job for lesson: #{lesson.title}"
      rescue => e
        puts "Failed to queue download job for lesson #{lesson.title}: #{e.message}"
      end
    end

    youtube_lectures.each do |lecture|
      begin
        YoutubeDownloadJob.perform_later('Lecture', lecture.id, 'video')
        puts "Queued video download job for lecture: #{lecture.title}"
      rescue => e
        puts "Failed to queue download job for lecture #{lecture.title}: #{e.message}"
      end
    end

    puts "\nMigration completed. #{youtube_lessons.count} lessons and #{youtube_lectures.count} lectures with YouTube URLs have been processed."
    puts "YouTube download jobs have been queued. Check the job queue status for progress."
  end

  def down
    Lesson.find_each do |lesson|
      if lesson.youtube_url.present?
        lesson.update_column(:video_url, lesson.youtube_url)
        lesson.update_column(:youtube_url, nil)
      end
    end

    Lecture.find_each do |lecture|
      if lecture.youtube_url.present?
        lecture.update_column(:video_url, lecture.youtube_url)
        lecture.update_column(:youtube_url, nil)
      end
    end

    remove_column :lessons, :youtube_url
    remove_column :lectures, :youtube_url
  end
end
