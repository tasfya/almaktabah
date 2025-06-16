require_relative './base'
require 'ruby-progressbar'

module Seeds
  class LecturesSeeder < Base
    def self.seed
      puts "📚 Seeding audio lectures..."

      # Ensure storage directories exist
      create_storage_directories

      lecture_array = load_json('data/lectures.json')
      total = lecture_array.size
      processed = 0

      progress = ProgressBar.create(
        total: total,
        format: "%a [%B] %p%% (%c/%C)",
        progress_mark: "▓",
        remainder_mark: "░"
      )

      lecture_array.each do |data|
        progress.increment

        next if data['name'].blank? || data['name'] =~ /^\d+$/
        title = data['name'].strip

        lecture = Lecture.find_or_initialize_by(title:) do |l|
          l.title = title
          l.category = data["series_name"]
          l.description = data['name']
          l.old_id = data['id']
          l.video_url = data['video_url'] if data['video_url'].present?
          l.published_date = Date.today
          l.views = 0
        end

        if lecture.save
          processed += 1

          # Download and process audio files
          if data['audio_url'].present?
            puts "📥 Downloading audio for lecture: #{lecture.title} (ID: #{lecture.id})"
            audio_path = Rails.root.join('storage', 'audio', 'lectures', "lecture_#{data["id"]}.mp3")
            downloaded_audio = download_file(data['audio_url'], audio_path)

            if downloaded_audio
              lecture.audio.attach(io: File.open(downloaded_audio), filename: File.basename(downloaded_audio)) if downloaded_audio
              puts "🔄 Queuing audio optimization job for lecture: #{lecture.title} (ID: #{lecture.id})"
              ProcessLectureMediaJob.perform_later(lecture.id, 'audio')
            else
              puts "❌ Failed to download audio for lecture: #{lecture.title}"
            end
          end

          # Download and process video files
          if data['video_url'].present?
            if data['video_url'].end_with?('.mp4')
              puts "📥 Downloading video for lecture: #{lecture.title} (ID: #{lecture.id})"
              video_path = Rails.root.join('storage', 'video', 'lectures', "lecture_#{data["id"]}.mp4")
              downloaded_video = download_file(data['video_url'], video_path)

              if downloaded_video
                lecture.video.attach(io: File.open(downloaded_video), filename: File.basename(downloaded_video)) if downloaded_video
                puts "🔄 Queuing video processing job for lecture: #{lecture.title} (ID: #{lecture.id})"
                ProcessLectureMediaJob.perform_later(lecture.id, 'video')
              else
                puts "❌ Failed to download video for lecture: #{lecture.title}"
              end
            else
              # Just store the video URL, don't download
              lecture.update(video_url: data['video_url'])
              puts "🔗 Set video URL for lecture: #{lecture.title} (ID: #{lecture.id})"
            end
          end
        end
      end

      puts "\n✅ Successfully seeded #{processed} lectures out of #{total}"
      puts "🔄 Media processing jobs have been queued. Audio will be optimized and videos will be processed in the background."
    end
  end
end
