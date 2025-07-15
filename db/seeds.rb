Dir[Rails.root.join("db/seeds/*.rb")].each { |file| require file unless file.end_with?("seeds.rb") }

SEEDERS = {
  "books" => Seeds::BooksSeeder,
  "benefits" => Seeds::BenefitsSeeder,
  "lessons" => Seeds::LessonsSeeder,
  "news" => Seeds::NewsSeeder
}

parts = ENV["PARTS"]&.split(",") || SEEDERS.keys
starting_from = ENV["FROM"]&.strip

domain_id = ENV["DOMAIN_ID"]
if domain_id
  Domain.find(domain_id) || raise("Domain with ID #{domain_id} not found")
else
  puts "No domain ID specified, using default."
end

puts "Running seeders for: #{parts.join(', ')}"

parts.each do |part|
  seeder = SEEDERS[part.strip]
  if seeder
    seeder.seed(from: starting_from, domain_id: domain_id)
  else
    puts "⚠️ Unknown seed part: #{part}"
  end
end

puts "✅ Seeding complete."
