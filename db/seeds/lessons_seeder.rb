require_relative './base'
require 'streamio-ffmpeg'

module Seeds
  class LessonsSeeder < Base
    ALFAWZAN_LESSONS = [
      {
        'name' => 'الدرس الأول من شرح الأصول الثلاثة',
        'series_name' => 'شرح الأصول الثلاثة',
        'position' => 1
      },
      {
        'name' => 'الدرس الثاني من شرح الأصول الثلاثة',
        'series_name' => 'شرح الأصول الثلاثة',
        'position' => 2
      },
      {
        'name' => 'الدرس الثالث من شرح الأصول الثلاثة',
        'series_name' => 'شرح الأصول الثلاثة',
        'position' => 3
      }
    ].freeze

    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      scholar ||= default_scholar
      lesson_array = if scholar.last_name.include?("الفوزان")
        ALFAWZAN_LESSONS
      else
        load_json('data/lessons.json')
      end

      puts "📚 Seeding audio lessons for #{scholar.first_name} #{scholar.last_name}..."
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
          series.description = "مجموعة #{data['series_name']} للشيخ #{scholar.first_name} #{scholar.last_name}"
          series.category = data["series_name"]
          series.scholar = scholar
          series.published_at = Date.today
          series.published = true
          unless series.save
            puts "❌ Failed to save series: #{series.title}"
            puts "Errors: #{series.errors.full_messages.join(', ')}"
            next
          else
            assign_to_domains(series, domain_ids)
          end
        end

        lesson = Lesson.find_or_initialize_by(title: name)
        if lesson.new_record?
          lesson.series = series
          lesson.description = name
          lesson.video_url = data['video_url']
          lesson.youtube_url = data['youtube_url']
          lesson.position = data['position'].to_i
          lesson.old_id = data['id']
          lesson.published_at = Date.today
          lesson.published = true
        end

        begin
          lesson.save!
          processed << lesson
          assign_to_domains(lesson, domain_ids)
          unless lesson.audio.attached?
            attach_fixture(lesson, :audio, :audio)
            extract_audio_duration(lesson)
          end
          print "."
        rescue ActiveRecord::RecordInvalid
          puts "❌ Failed: #{lesson.title} — #{lesson.errors.full_messages.join(', ')}"
          failed << lesson
        end
      end

      puts "\n==== Seeding Summary ===="
      puts "Total lessons in source: #{total}"
      puts "Lessons processed (saved): #{processed.size}"
      puts "Lessons failed to save: #{failed.size}"
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
