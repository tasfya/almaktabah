require_relative './base'

module Seeds
  class BooksSeeder < Base
    ALFAWZAN_BOOKS = [
      { name: "الإرشاد إلى صحيح الاعتقاد" },
      { name: "شرح كتاب التوحيد" },
      { name: "الملخص الفقهي" }
    ].freeze

    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      scholar ||= default_scholar
      books_data = if scholar.full_name&.include?("الفوزان")
        ALFAWZAN_BOOKS
      else
        load_json('data/books.json').find { |item| item['type'] == 'table' }['data']
      end

      puts "Seeding books for #{scholar.full_name}..."
      processed = 0

      books_data.each do |data|
        name = data['name'] || data[:name]
        next if name.blank? || name =~ /^\d+$/

        book = Book.find_or_initialize_by(title: name) do |b|
          b.scholar = scholar
          b.description = "كتاب #{name} للشيخ #{scholar.full_name}"
          b.category = "الكتب"
          b.published_at = Date.today
          b.published = true
        end

        book.downloads ||= 0
        book.pages ||= 0

        if book.save
          attach_fixture(book, :cover_image, :cover) unless book.cover_image.attached?
          attach_fixture(book, :file, :pdf) unless book.file.attached?
          processed += 1
          assign_to_domains(book, domain_ids)
        end
        print "." if processed % 5 == 0
      end

      puts "\nSeeded #{processed} books"
    end
  end
end
