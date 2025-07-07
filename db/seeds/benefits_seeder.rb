require_relative './base'

module Seeds
  class BenefitsSeeder < Base
    def self.seed(from: nil)
      puts "📚 Seeding audio benefits..."

      benefit_array = load_json('data/benefits.json')
      total = benefit_array.size

      processed = []
      failed = []
      started = from.blank?

      benefit_array.each do |data|
        name = data['name']
        if !started
          started = (name == from)
          next unless started
        end

        if name.blank?
          puts "⚠️ Skipping benefit with invalid #{data["id"]} name: #{name || 'nil'}"
          next
        end

        benefit = Benefit.find_or_initialize_by(title: name)
        if benefit.new_record?
          benefit.category = data["series_name"]
          benefit.description = name
        end

        begin
          benefit.save!
          processed << benefit
          puts "✅ Successfully saved benefit: #{benefit.title} (ID: #{benefit.id})"
        rescue ActiveRecord::RecordInvalid
          puts "❌ Failed to save benefit: #{benefit.title}"
          puts "Errors: #{benefit.errors.full_messages.join(', ')}"
          failed << benefit
          next
        end

        if data['audio_url'].present?
          path = Rails.root.join('tmp', 'audio', 'benefits', "benefit_#{benefit.id}.mp3")
          if download_file(data['audio_url'], path)
            benefit.audio.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download audio for benefit: #{benefit.title}"
          end
        end

        if data['video_url'].present? && data['video_url'].end_with?('mp4')
          path = Rails.root.join('tmp', 'video', 'benefits', "benefit_#{benefit.id}.mp4")
          if download_file(data['video_url'], path)
            benefit.video.attach(io: File.open(path), filename: File.basename(path))
            CleanupTemporaryFilesJob.perform_later(path.to_s)
          else
            puts "❌ Failed to download video for benefit: #{benefit.title}"
          end
        end
      end

      puts "==== Seeding Summary ===="
      puts "Total benefits in source: #{total}"
      puts "Benefits processed (saved): #{processed.size}"
      puts "Benefits failed to save: #{failed.size}"
    end
  end
end
