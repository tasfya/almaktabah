class BenefitImportService
  def self.import_all(from: nil, batch_size: 10, domain_id: nil)
    new.import_all(from: from, batch_size: batch_size, domain_id: domain_id)
  end

  def import_all(from: nil, batch_size: 10, domain_id: nil)
    puts "📚 Starting benefit import process..."

    benefit_array = load_json_data
    total = benefit_array.size

    puts "Total benefits to process: #{total}"
    puts "Batch size: #{batch_size}"

    started = from.blank?
    queued_count = 0
    batch = []

    benefit_array.each_with_index do |benefit_data, index|
      name = benefit_data["name"]

      # Handle starting from a specific benefit
      if !started
        started = (name == from)
        next unless started
      end

      # Skip benefits with no name
      if name.blank?
        puts "⚠️ Skipping benefit with invalid #{benefit_data["id"]} name: #{name || 'nil'}"
        next
      end

      batch << benefit_data

      # Process batch when it reaches batch_size or at the end
      if batch.size >= batch_size || index == benefit_array.size - 1
        # Queue jobs with a slight delay to prevent overwhelming the queue
        batch.each_with_index do |data, batch_index|
          BenefitsSeedImportJob.set(wait: batch_index.seconds).perform_later(data, domain_id: domain_id)
          queued_count += 1
        end

        puts "✅ Queued batch of #{batch.size} benefits (total: #{queued_count})"
        batch = []
      end
    end

    puts "==== Import Summary ===="
    puts "Total benefits in source: #{total}"
    puts "Benefits queued for import: #{queued_count}"
    puts "Import jobs have been queued and will be processed in the background."
    puts "You can monitor progress with: rails benefits:status"
  end

  private

  def load_json_data
    JSON.parse(File.read(Rails.root.join("data/benefits.json")))
  end
end
