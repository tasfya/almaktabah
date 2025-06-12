require_relative './base'
require 'ruby-progressbar'

module Seeds
  class LecturesSeeder < Base
    def self.seed
      puts "📚 Seeding audio lectures..."

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
        lecture = Lecture.find_or_initialize_by(title: data['name']) do |l|
          l.category = data["series_name"]
          l.description = data['name']
          l.video_url = data['video_url'] if data['video_url'].present? && !data['video_url'].end_with?('mp4')
          l.published_date = Date.today
          l.views = 0
        end

        if data['audio_url'].present? && !lecture.audio.attached?
          path = Rails.root.join('storage', 'audio', "lectures", "lecture_#{data["id"]}.mp3")
          downloaded = download_file(data['audio_url'], path)
          lecture.audio.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
        end

        if data['video_url'].present? && !lecture.video.attached?
            if data['video_url'].end_with?('mp4')
                path = Rails.root.join('storage', 'video', "lectures", "lecture_#{data["id"]}.mp4")
                downloaded = download_file(data['video_url'], path)
                lecture.video.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded    
            end
        end


        processed += 1 if lecture.save
      end

      puts "\n✅ Successfully seeded #{processed} lectures out of #{total}"
    end
  end
end
