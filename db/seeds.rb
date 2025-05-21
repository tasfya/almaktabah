# db/seeds.rb

require 'open-uri'
require 'json'
require 'fileutils'

puts "Starting seed data process..."

# Create base upload directories
[ 'books', 'covers', 'audio' ].each do |dir|
  FileUtils.mkdir_p(Rails.root.join('storage', dir))
end

# Create or find default scholar (author)
puts "Finding or creating scholar..."
scholar = Scholar.find_or_create_by(first_name: "محمد", last_name: "بن رمزان الهاجري")

# Load category data
puts "Loading category data..."
category_data = JSON.parse(File.read(Rails.root.join('data', 'category.json')))

# Create or find series based on categories
puts "Finding or creating series..."
series_hash = {}

# Create audio library series
audio_series = Series.find_or_create_by(title: "المكتبة الصوتية") do |series|
  series.description = "مجموعة من الدروس الصوتية للشيخ محمد بن رمزان الهاجري"
  series.category = "المكتبة الصوتية"
  series.published_date = Date.today
end
series_hash["39"] = audio_series

# Create series for each category with parent_id 41 (lesson series)
category_data.select { |cat| cat["parent_id"] == "41" }.each do |cat|
  series = Series.find_or_create_by(title: cat["child_name"]) do |s|
    s.description = "سلسلة #{cat["child_name"]} للشيخ محمد بن رمزان الهاجري"
    s.category = "الدروس"
    s.published_date = Date.today
  end
  series_hash[cat["child_id"]] = series
end

# Default audio series fallback
default_audio_series = series_hash["39"] || audio_series

# Function to download real files
def download_file(url, destination_path, base_url = "https://mohammed-ramzan.com")
  begin
    return nil if url.blank?

    full_url = url.start_with?('http') ? url : "#{base_url}/#{url}"

    FileUtils.mkdir_p(File.dirname(destination_path))

    if File.exist?(destination_path)
      puts "File already exists: #{destination_path}"
      return destination_path
    end

    URI.open(full_url) do |file|
      File.open(destination_path, 'wb') do |output|
        output.write(file.read)
      end
    end

    puts "Downloaded: #{url} to #{destination_path}"
    destination_path
  rescue StandardError => e
    puts "Error downloading #{url}: #{e.message}"
    nil
  end
end

# Process books
puts "Loading books data..."
books_data = JSON.parse(File.read(Rails.root.join('data', 'books.json')))
books_array = books_data.find { |item| item['type'] == 'table' }['data']
processed_books = 0

puts "Processing books..."
books_array.each do |book_data|
  next if book_data['name'].blank? || book_data['name'] =~ /^[0-9]+$/

  book = Book.find_or_initialize_by(title: book_data['name']) do |b|
    b.author = scholar
    b.description = "كتاب #{book_data['name']} للشيخ محمد بن رمزان الهاجري"
    b.category = "الكتب"
    b.published_date = Date.today
  end

  book.views = book_data['counter'].to_i if book_data['counter'].present?
  book.downloads = 0
  book.pages = 0

  if book_data['image'].present? && !book.cover_image.attached?
    cover_path = Rails.root.join('storage', 'covers', "book_#{book_data['id']}_cover#{File.extname(book_data['image'])}")
    downloaded_cover = download_file(book_data['image'], cover_path)

    if downloaded_cover && File.exist?(downloaded_cover)
      book.cover_image.attach(io: File.open(downloaded_cover), filename: File.basename(downloaded_cover), content_type: 'image/png')
    end
  end

  if book_data['url'].present? && !book.file.attached?
    pdf_path = Rails.root.join('storage', 'books', "book_#{book_data['id']}#{File.extname(book_data['url'])}")
    downloaded_pdf = download_file(book_data['url'], pdf_path)

    if downloaded_pdf && File.exist?(downloaded_pdf)
      book.file.attach(io: File.open(downloaded_pdf), filename: File.basename(downloaded_pdf), content_type: 'application/pdf')
    end
  end

  if book.save
    processed_books += 1
    print "." if processed_books % 5 == 0
  else
    puts "\nError saving book #{book_data['name']}: #{book.errors.full_messages.join(', ')}"
  end
end

puts "\nProcessed #{processed_books} books (total: #{Book.count})"

# Process lessons
puts "Loading lessons data..."
lessons_data = JSON.parse(File.read(Rails.root.join('data', 'lessons.json')))
lessons_array =
  if lessons_data.is_a?(Array) && !lessons_data.any? { |item| item['type'] == 'table' }
    lessons_data
  else
    table = lessons_data.find { |item| item['type'] == 'table' }
    table ? table['data'] : lessons_data
  end

lessons_array.reject! { |l| l == "]" } # Cleanup edge case

# Build category mapping
category_map = {}
category_data.each do |cat|
  if cat["parent_id"] == "39"
    category_map[cat["child_id"]] = series_hash[cat["child_id"]] || audio_series
  elsif cat["parent_id"] == "41"
    category_map[cat["child_id"]] = series_hash[cat["child_id"]]
  end
end

puts "Processing lessons..."
processed_lessons = 0

lessons_array.each do |lesson_data|
  next if lesson_data['name'].blank? || lesson_data['name'] =~ /^[0-9]+$/

  lesson_category = lesson_data['category_name'] || "المكتبة الصوتية"
  content_type = lesson_category.include?("مرئية") ? "video" : "audio"

  series =
    if lesson_data['category_id'] && category_map[lesson_data['category_id']]
      category_map[lesson_data['category_id']]
    elsif lesson_category.include?("الدروس")
      Series.find_by(category: "الدروس")
    else
      audio_series
    end

  if series.nil?
    series = Series.find_or_create_by(title: lesson_category) do |s|
      s.description = "مجموعة #{lesson_category}"
      s.category = lesson_category
      s.published_date = Date.today
    end
  end

  lesson = Lesson.find_or_initialize_by(title: lesson_data['name']) do |l|
    l.series = series
    l.category = lesson_category
    l.content_type = content_type
    l.published_date = Date.today
    l.duration = 15*60
    l.description = lesson_data['name']
    l.view_count = lesson_data['counter'].to_i if lesson_data['counter'].present?
  end

  if lesson_data['image'].present? && !lesson.audio.attached?
    audio_path = Rails.root.join('storage', 'audio', "lesson_#{lesson_data['id']}#{File.extname(lesson_data['image'])}")
    downloaded_audio = download_file(lesson_data['image'], audio_path)

    if downloaded_audio && File.exist?(downloaded_audio)
      lesson.audio.attach(io: File.open(downloaded_audio), filename: File.basename(downloaded_audio), content_type: 'audio/mpeg')
    end
  end

  unless lesson.thumbnail.attached?
    thumbnail_path = Rails.root.join('storage', 'audio', "lesson_#{lesson_data['id']}_thumbnail.png")
    icon_path = Rails.root.join('public', 'icon.png')
    FileUtils.cp(icon_path, thumbnail_path) if File.exist?(icon_path)

    if File.exist?(thumbnail_path)
      lesson.thumbnail.attach(io: File.open(thumbnail_path), filename: File.basename(thumbnail_path), content_type: 'image/png')
    end
  end

  if lesson.save
    processed_lessons += 1
    print "." if processed_lessons % 10 == 0
  else
    puts "\nError saving lesson #{lesson_data['name']}: #{lesson.errors.full_messages.join(', ')}"
  end
end

puts "\nProcessed #{processed_lessons} lessons (total: #{Lesson.count})"
puts "Seed data process completed!"
