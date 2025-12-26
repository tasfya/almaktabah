require_relative './base'

module Seeds
  class LecturesSeeder < Base
    ALFAWZAN_LECTURES = [
      {
        'name' => 'شرح العقيدة الواسطية - المقدمة',
        'category' => 'العقيدة',
        'kind' => 'sermon'
      },
      {
        'name' => 'شرح كشف الشبهات',
        'category' => 'العقيدة',
        'kind' => 'conference'
      },
      {
        'name' => 'التعليق على كتاب الصلاة',
        'category' => 'الفقه',
        'kind' => 'benefit'
      }
    ].freeze

    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      scholar ||= default_scholar
      lecture_array = if scholar.last_name.include?("الفوزان")
        ALFAWZAN_LECTURES
      else
        load_json('data/lectures.json')
      end

      puts "📚 Seeding audio lectures for #{scholar.first_name} #{scholar.last_name}..."
      total = lecture_array.size

      processed = []
      failed = []
      started = from.blank?

      lecture_array.each_with_index do |data, index|
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
          lecture.scholar = scholar
          lecture.description = name
          lecture.video_url = data['video_url']
          lecture.youtube_url = data['youtube_url']
          lecture.category = data['category']
          lecture.kind = data['kind'] if data['kind'].present?
          lecture.old_id = data['id']
          lecture.published_at = Date.today
          lecture.published = true
        end

        begin
          lecture.save!
          processed << lecture
          assign_to_domains(lecture, domain_ids)
          unless lecture.audio.attached?
            attach_fixture(lecture, :audio, :audio)
            extract_audio_duration(lecture)
          end
          if index == 0 && !lecture.video.attached?
            attach_fixture(lecture, :video, :video)
          end
          print "."
        rescue ActiveRecord::RecordInvalid
          puts "❌ Failed: #{lecture.title} — #{lecture.errors.full_messages.join(', ')}"
          failed << lecture
        end
      end

      puts "\n==== Seeding Summary ===="
      puts "Total lectures in source: #{total}"
      puts "Lectures processed (saved): #{processed.size}"
      puts "Lectures failed to save: #{failed.size}"
    end

    def self.extract_audio_duration(record)
      return unless record.audio.attached?

      record.audio.open do |file|
        movie = FFMPEG::Movie.new(file.path)
        record.update_column(:duration, movie.duration.to_i) if movie.duration
      end
    rescue => e
      puts "⚠️ Duration extraction failed: #{e.message}"
    end
  end
end
