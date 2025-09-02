namespace :friendly_id do
  desc "Generate slugs for existing records"
  task generate_slugs: :environment do
    models = [ Series, Lecture, Book, News, Fatwa, Benefit ]
    puts "Generating slugs for existing records..."
    models.each do |model|
      model.find_each(batch_size: 100) do |record|
        record.slug = nil
        record.save!
      end
      puts "Slugs generated for #{model.name}"
    end
    puts "Slug generation completed."
  rescue => e
    puts "Error generating slugs: #{e.message}"
    exit 1
  end
end
