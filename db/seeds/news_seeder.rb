require_relative './base'
require 'active_support/inflector'

module Seeds
  class NewsSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      puts "📰 Seeding news..."

      news_array = load_json('data/news.json')
      processed = 0
      errors = []

      news_array.each_with_index do |data, index|
        puts "Processing ##{index + 1}: #{data['name']}" if data['name'].present?
        next if data['name'].blank? || data['name'] =~ /^\d+$/

        begin
          title = data['name'].strip
          content_text = data['description'].presence || title

          news = News.find_or_initialize_by(title: title, slug: title.parameterize)
          news.description ||= title
          news.published_at ||= Date.today
          news.content = content_text if news.content.blank?

          # Attach thumbnail if provided
          if data['url'].present? && !news.thumbnail.attached?
            path = Rails.root.join('storage', 'audio', "news_#{data['id']}_thumbnail#{File.extname(data['url'])}")
            downloaded = download_file(data['url'], path)
            if downloaded
              news.thumbnail.attach(io: File.open(downloaded), filename: File.basename(downloaded))
            else
              errors << "❌ Failed to download thumbnail for: #{title}"
            end
          end

          if news.save
            processed += 1
            print "." if processed % 10 == 0
          else
            errors << "❌ Failed to save news: #{title} — #{news.errors.full_messages.join(', ')}"
          end

        rescue => e
          errors << "❌ Exception for '#{data['name']}': #{e.message}"
        end
      end

      puts "\n✅ Seeded #{processed} news items"
      if errors.any?
        puts "\n⚠️ Completed with #{errors.count} errors:"
        errors.each { |err| puts "  - #{err}" }
      else
        puts "✅ No errors encountered."
      end
    end
  end
end
