require_relative './base'

module Seeds
  class VideoLessonsSeeder < Base
    def self.seed
      puts "Seeding video lessons..."

      video_array = load_json('data/lesson-v.json')
      processed = 0

      video_array.each do |data|
        next if data['name'].blank? || data['name'] =~ /^\d+$/
        category = data['parent_catname']
        series = Series.find_or_create_by(title: category) do |s|
          s.description = "مجموعة #{data['category']} للشيخ محمد بن رمزان الهاجري"
          s.category = data['category']
          s.published_date = Date.today
        end

        lesson = Lesson.find_or_initialize_by(title: data['name']) do |l|
          l.series = series
          l.category = category
          l.published_date = Date.today
          l.duration = 15 * 60
          l.description = data['name']
          l.video_url = data['url']
          l.view_count = data['counter'].to_i if data['counter']
        end

        lesson.video_url = data['url'] if data['url'].present?

        if data['cover_image'].present? && !lesson.thumbnail.attached?
          path = Rails.root.join('storage', 'audio', "lesson_#{data['id']}_thumbnail#{File.extname(data['cover_image'])}")
          downloaded = download_file(data['cover_image'], path)
          lesson.thumbnail.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
        end

        unless lesson.thumbnail.attached?
          fallback_path = Rails.root.join('public', 'icon.png')
          thumb_path = Rails.root.join('storage', 'audio', "lesson_#{data['id']}_thumbnail.png")
          FileUtils.cp(fallback_path, thumb_path) if File.exist?(fallback_path)
          lesson.thumbnail.attach(io: File.open(thumb_path), filename: File.basename(thumb_path)) if File.exist?(thumb_path)
        end

        processed += 1 if lesson.save
        print "." if processed % 10 == 0
      end

      puts "\nSeeded #{processed} video lessons"
    end
  end
end
