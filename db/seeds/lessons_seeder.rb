require_relative './base'
require 'ruby-progressbar'

module Seeds
  class LessonsSeeder < Base
    def self.seed
      puts "📚 Seeding audio lessons..."

      lesson_array = load_json('data/lessons.json')
      total = lesson_array.size
      processed = 0

      progress = ProgressBar.create(
        total: total,
        format: "%a [%B] %p%% (%c/%C)",
        progress_mark: "▓",
        remainder_mark: "░"
      )

      lesson_array.each do |data|
        progress.increment

        next if data['name'].blank? || data['name'] =~ /^\d+$/

        series = Series.find_or_initialize_by(title: data["series_name"])
        if series.new_record?
          series.description = "مجموعة #{data['series_name']} للشيخ محمد بن رمزان الهاجري"
          series.category = data["series_name"]
          series.published_date = Date.today

          unless series.save
            puts "❌ Failed to save series: #{series.title}"
            puts "Errors: #{series.errors.full_messages.join(', ')}"
            next
          end
        end


        lesson = Lesson.find_or_initialize_by(title: data['name']) do |l|
          l.title = data['name']
          l.series = series
          l.category = data["series_name"]
          l.description = data['name']
          l.video_url = data['video_url']
          l.published_date = Date.today
          l.duration = 100
          l.old_id = data['id']
          l.view_count = 0
        end
        # report validation errors if any
        unless lesson.valid?
          errors = lesson.errors.full_messages.join(', ')
        end
        puts "Processing lesson: #{lesson.title} (ID: #{lesson.id})"
        if data['audio_url'].present? && !lesson.audio.attached?
          path = Rails.root.join('storage', 'audio', "lessons", "lesson_#{data["id"]}.mp3")
          downloaded_audio = download_file(data['audio_url'], path)
          if downloaded_audio
            lesson.audio.attach(io: File.open(downloaded_audio), filename: File.basename(downloaded_audio)) if downloaded_audio
            puts "🔄 Queuing audio optimization job for lesson: #{lesson.title} (ID: #{lesson.id})"
            ProcessLessonMediaJob.perform_later(lesson.id, 'audio')
          else
            puts "❌ Failed to download audio for lesson: #{lesson.title}"
          end
        end


        if data['video_url'].present? && !lesson.video.attached?
            if data['video_url'].end_with?('mp4')
              path = Rails.root.join('storage', 'video', "lessons", "lesson_#{data["id"]}.mp4")
              downloaded = download_file(data['video_url'], path)
              if downloaded
                lesson.video.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
                puts "🔄 Queuing video processing job for lesson: #{lesson.title} (ID: #{lesson.id})"
                ProcessLessonMediaJob.perform_later(lesson.id, 'video')
              else
                puts "❌ Failed to download video for lesson: #{lesson.title}"
              end
            end
        end

        processed += 1
      end

      puts "\n✅ Successfully seeded #{processed} lessons out of #{total}"
    end
  end
end
