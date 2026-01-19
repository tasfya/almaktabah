require_relative './base'
require 'active_support/inflector'

module Seeds
  class NewsSeeder < Base
    ALFAWZAN_NEWS = [
      {
        'name' => 'إعلان عن محاضرة جديدة للشيخ صالح الفوزان',
        'description' => 'يسر موقع العلامة صالح الفوزان أن يعلن عن محاضرة جديدة في شرح كتاب التوحيد'
      }
    ].freeze

    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      scholar ||= default_scholar
      news_array = if scholar.full_name&.include?("الفوزان")
        ALFAWZAN_NEWS
      else
        load_json('data/news.json')
      end

      puts "📰 Seeding news for #{scholar.full_name}..."
      processed = 0

      news_array.each do |data|
        name = data['name']
        next if name.blank? || name =~ /^\d+$/

        title = name.strip
        slug = title.parameterize
        next if News.exists?(slug: slug)

        news = News.new(
          title: title,
          slug: slug,
          description: data['description'].presence,
          content: data['description'].presence || title,
          published_at: Date.today,
          published: true,
          scholar: scholar
        )

        if news.save
          attach_fixture(news, :thumbnail, :thumbnail)
          assign_to_domains(news, domain_ids)
          processed += 1
          print "."
        end
      end

      puts "\n✅ Seeded #{processed} news items"
    end
  end
end
