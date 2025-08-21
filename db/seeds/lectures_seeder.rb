require_relative './base'

module Seeds
  class LecturesSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      puts "📚 Seeding audio lectures..."

      lecture_array = load_json('data/lectures.json')
      total = lecture_array.size

      processed = []
      failed = []
      started = from.blank?

      lecture_array.each do |data|
        name = data['name']

        if !started
          started = (name == from)
          next unless started
        end

        if name.blank?
          puts "⚠️ Skipping lecture with invalid #{data['id']} name: #{name || 'nil'}"
          next
        end

        lecture = Lecture.find_or_initialize_by(title: name)
        if lecture.new_record?
          lecture.scholar = default_scholar
          lecture.description = name
          lecture.video_url = data['video_url']
          lecture.youtube_url = data['youtube_url']
          lecture.category = data['category']
          lecture.old_id = data['id']
          lecture.published_at = Date.today
          lecture.published = true
        end

        begin
          lecture.save!
          processed << lecture
          assign_to_domain(lecture, domain_id)
          puts "✅ Successfully saved lecture: #{lecture.title} (ID: #{lecture.id})"
        rescue ActiveRecord::RecordInvalid
          puts "❌ Failed to save lecture: #{lecture.title}"
          puts "Errors: #{lecture.errors.full_messages.join(', ')}"
          failed << lecture
          next
        end

        if data['audio_url'].present?
          path = Rails.root.join('tmp', 'audio', 'lectures', "lecture_#{lecture.id}.mp3")
          if download_file(data['audio_url'], path)
            lecture.audio.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download audio for lecture: #{lecture.title}"
          end
        end

        if data['video_url'].present? && data['video_url'].end_with?('mp4')
          path = Rails.root.join('tmp', 'video', 'lectures', "lecture_#{lecture.id}.mp4")
          if download_file(data['video_url'], path)
            lecture.video.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download video for lecture: #{lecture.title}"
          end
        end
      end

      puts "\n==== Seeding Summary ===="
      puts "Total lectures in source: #{total}"
      puts "Lectures processed (saved): #{processed.size}"
      puts "Lectures failed to save: #{failed.size}"
    end
  end
end
