Dir[Rails.root.join("db/seeds/*.rb")].each { |file| require file unless file.end_with?("seeds.rb") }

SEEDERS = {
  "users" => Seeds::UsersSeeder,
  "books" => Seeds::BooksSeeder,
  "lessons" => Seeds::LessonsSeeder,
  "lectures" => Seeds::LecturesSeeder,
  "news" => Seeds::NewsSeeder,
  "fatwas" => Seeds::FatwasSeeder
}

parts = ENV["PARTS"]&.split(",") || SEEDERS.keys
starting_from = ENV["FROM"]&.strip

domain_ids = if ENV["DOMAIN_ID"]
  [ ENV["DOMAIN_ID"].to_i ]
else
  # Create two domains: 127.0.0.1 with default template, localhost with 3ilm template
  domain1 = Domain.find_or_create_by!(host: "127.0.0.1") do |domain|
    domain.name = "Default Domain"
    domain.template_name = "default"
  end

  domain2 = Domain.find_or_create_by!(host: "localhost") do |domain|
    domain.name = "Localhost Domain"
    domain.template_name = "3ilm"
  end

  puts "Using domains:"
  puts "  - #{domain1.name} (#{domain1.host}) with template '#{domain1.template_name}' (ID: #{domain1.id})"
  puts "  - #{domain2.name} (#{domain2.host}) with template '#{domain2.template_name}' (ID: #{domain2.id})"

  [ domain1.id, domain2.id ]
end

puts "Running seeders for: #{parts.join(', ')}"

parts.each do |part|
  seeder = SEEDERS[part.strip]
  if seeder
    seeder.seed(from: starting_from, domain_ids: domain_ids)
  else
    puts "⚠️ Unknown seed part: #{part}"
  end
end

puts "✅ Seeding complete."
