require_relative './base'

module Seeds
  class BooksSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      puts "Seeding books..."
      scholar = Scholar.find_or_create_by(first_name: "محمد", last_name: "بن رمزان الهاجري")
      books_data = load_json('data/books.json').find { |item| item['type'] == 'table' }['data']
      processed = 0

      books_data.each do |data|
        next if data['name'].blank? || data['name'] =~ /^\d+$/

        book = Book.find_or_initialize_by(title: data['name']) do |b|
          b.author = scholar
          b.description = "كتاب #{data['name']} للشيخ محمد بن رمزان الهاجري"
          b.category = "الكتب"
          b.published_at = Date.today
        end

        book.downloads ||= 0
        book.pages ||= 0

        if data['image'].present? && !book.cover_image.attached?
          path = Rails.root.join('storage', 'covers', "book_#{data['id']}_cover#{File.extname(data['image'])}")
          downloaded = download_file(data['image'], path)
          book.cover_image.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
        end

        if data['url'].present? && !book.file.attached?
          path = Rails.root.join('storage', 'books', "book_#{data['id']}#{File.extname(data['url'])}")
          downloaded = download_file(data['url'], path)
          book.file.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
        end

        processed += 1 if book.save
        print "." if processed % 5 == 0
      end

      puts "\nSeeded #{processed} books"
    end
  end
end
