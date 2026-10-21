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

domain1_host = ENV.fetch("SEED_DOMAIN_HOST", "127.0.0.1")
domain1 = Domain.find_or_initialize_by(host: domain1_host)
domain1.name = domain1_host
domain1.title ||= "الشيخ محمد بن رمزان الهاجري"
domain1.description ||= "الموقع الرسمي لفضيلة الشيخ محمد بن رمزان الهاجري - كتب ومحاضرات ودروس وفتاوى"
domain1.save!

domain2 = Domain.find_or_initialize_by(host: "localhost")
domain2.name = Domain::ILM_NAME
domain2.title ||= "العلم"
domain2.description ||= "موقع العلم الشرعي - مجموعة من الكتب والمحاضرات والدروس"
domain2.save!

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
