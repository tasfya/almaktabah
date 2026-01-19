Dir[Rails.root.join("db/seeds/*.rb")].each { |file| require file unless file.end_with?("seeds.rb") }

SEEDERS = {
  "users" => Seeds::UsersSeeder,
  "books" => Seeds::BooksSeeder,
  "lessons" => Seeds::LessonsSeeder,
  "lectures" => Seeds::LecturesSeeder,
  "news" => Seeds::NewsSeeder,
  "fatwas" => Seeds::FatwasSeeder,
  "articles" => Seeds::ArticlesSeeder
}

CONTENT_SEEDERS = SEEDERS.except("users")

parts = ENV["PARTS"]&.split(",") || SEEDERS.keys
starting_from = ENV["FROM"]&.strip

domain1 = Domain.find_or_create_by!(host: "127.0.0.1") do |domain|
  domain.name = "127.0.0.1"
  domain.title = "الشيخ محمد بن رمزان الهاجري"
  domain.description = "الموقع الرسمي لفضيلة الشيخ محمد بن رمزان الهاجري - كتب ومحاضرات ودروس وفتاوى"
end

domain2 = Domain.find_or_create_by!(host: "localhost") do |domain|
  domain.name = "localhost"
  domain.title = "العلم"
  domain.description = "موقع العلم الشرعي - مجموعة من الكتب والمحاضرات والدروس"
end

hajri_scholar = Seeds::Base.default_scholar
alfawzan_scholar = Seeds::Base.alfawzan_scholar(default_domain: domain2)

puts "=== Seeding Hajri content (both domains) ==="

parts.each do |part|
  seeder = SEEDERS[part.strip]
  if seeder
    seeder.seed(from: starting_from, domain_ids: [ domain1.id, domain2.id ], scholar: hajri_scholar)
  else
    puts "⚠️ Unknown seed part: #{part}"
  end
end

puts "\n=== Seeding Alfawzan content (localhost only) ==="

(parts.map(&:strip) & CONTENT_SEEDERS.keys).each do |part|
  seeder = CONTENT_SEEDERS[part]
  seeder&.seed(from: starting_from, domain_ids: [ domain2.id ], scholar: alfawzan_scholar)
end

puts "✅ Seeding complete."

puts "🔍 Triggering Typesense reindex..."
Rake::Task["typesense:reindex"].invoke
puts "✅ Typesense reindex complete."
