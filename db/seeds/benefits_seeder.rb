require_relative './base'

module Seeds
  class BenefitsSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      puts "Seeding benefits..."
      scholar = default_scholar
      benefits_data = load_json('data/benefits.json')
      processed = 0

      benefits_data.each do |data|
        next if data['name'].blank?

        benefit = Benefit.find_or_initialize_by(title: data['name']) do |b|
          b.scholar = scholar
          b.description = data['name']
          b.category = data['series_name'] || "المنافع"
          b.published = true
        end

        # Handle audio attachment if present
        if data['image'].present? && !benefit.audio.attached?
          path = Rails.root.join('storage', 'audio', "benefit_#{data['id']}#{File.extname(data['image'])}")
          downloaded = download_file(data['image'], path)
          benefit.audio.attach(io: File.open(downloaded), filename: File.basename(downloaded)) if downloaded
        end

        if benefit.save
          processed += 1
          assign_to_domain(benefit, domain_id)
        end
        print "." if processed % 5 == 0
      end

      puts "\nSeeded #{processed} benefits"
    end
  end
end
