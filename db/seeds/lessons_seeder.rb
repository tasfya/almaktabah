require_relative './base'

module Seeds
  class LessonsSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      puts "📚 Seeding audio lessons..."

      lesson_array = load_json('data/lessons.json')
      total = lesson_array.size

      processed = []
      failed = []
      started = from.blank?

      lesson_array.each do |data|
        name = data['name']

        if !started
          started = (name == from)
          next unless started
        end

        if name.blank?
          puts "⚠️ Skipping lesson with invalid #{data['id']} name: #{name || 'nil'}"
          next
        end

        series = Series.find_or_initialize_by(title: data["series_name"])
        if series.new_record?
          series.description = "مجموعة #{data['series_name']} للشيخ محمد بن رمزان الهاجري"
          series.category = data["series_name"]
          # Assign a scholar to satisfy validation
          series.scholar = default_scholar
          unless series.save
            puts "❌ Failed to save series: #{series.title}"
            puts "Errors: #{series.errors.full_messages.join(', ')}"
            next
          else
            assign_to_domain(series, domain_id)
          end
        end

        lesson = Lesson.find_or_initialize_by(title: name)
        if lesson.new_record?
          lesson.series = series
          lesson.category = data["series_name"]
          lesson.description = name
          lesson.video_url = data['video_url']
          lesson.youtube_url = data['youtube_url']
          lesson.position = data['position'].to_i
          lesson.old_id = data['id']
          lesson.published = true
        end

        begin
          lesson.save!
          processed << lesson
          assign_to_domain(lesson, domain_id)
          puts "✅ Successfully saved lesson: #{lesson.title} (ID: #{lesson.id})"
        rescue ActiveRecord::RecordInvalid
          puts "❌ Failed to save lesson: #{lesson.title}"
          puts "Errors: #{lesson.errors.full_messages.join(', ')}"
          failed << lesson
          next
        end

        if data['audio_url'].present?
          path = Rails.root.join('tmp', 'audio', 'lessons', "lesson_#{lesson.id}.mp3")
          if download_file(data['audio_url'], path)
            lesson.audio.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download audio for lesson: #{lesson.title}"
          end
        end

        if data['video_url'].present? && data['video_url'].end_with?('mp4')
          path = Rails.root.join('tmp', 'video', 'lessons', "lesson_#{lesson.id}.mp4")
          if download_file(data['video_url'], path)
            lesson.video.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download video for lesson: #{lesson.title}"
          end
        end
      end

      puts "\n==== Seeding Summary ===="
      puts "Total lessons in source: #{total}"
      puts "Lessons processed (saved): #{processed.size}"
      puts "Lessons failed to save: #{failed.size}"
    end
  end
end
