Dir[Rails.root.join("db/seeds/*.rb")].each { |file| require file unless file.end_with?("seeds.rb") }

SEEDERS = {
  "books" => Seeds::BooksSeeder,
  "lectures" => Seeds::LecturesSeeder,
  "lessons" => Seeds::LessonsSeeder,
  "news" => Seeds::NewsSeeder
}

parts = ENV["PARTS"]&.split(",") || SEEDERS.keys
starting_from = ENV["FROM"]&.strip

puts "Running seeders for: #{parts.join(', ')}"

parts.each do |part|
  seeder = SEEDERS[part.strip]
  if seeder
    seeder.seed(from: starting_from)
  else
    puts "⚠️ Unknown seed part: #{part}"
  end
end

puts "✅ Seeding complete."
