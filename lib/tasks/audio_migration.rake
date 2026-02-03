namespace :audio do
  desc "Migrate optimized_audio to final_audio for all fatwas"
  task migrate_to_final: :environment do
    total = Fatwa.where.not(id: Fatwa.left_joins(:optimized_audio_attachment).where(active_storage_attachments: { id: nil }).select(:id)).count
    migrated = 0
    failed = 0
    skipped = 0

    puts "Starting migration of #{total} fatwas with optimized_audio..."

    Fatwa.includes(:scholar, :optimized_audio_attachment, :final_audio_attachment).find_each.with_index do |fatwa, index|
      next unless fatwa.optimized_audio.attached?

      if fatwa.final_audio.attached?
        skipped += 1
        print "."
        next
      end

      if fatwa.migrate_to_final_audio
        migrated += 1
        print "✓"
      else
        failed += 1
        print "✗"
      end

      # Progress update every 50 records
      if (index + 1) % 50 == 0
        puts " [#{index + 1}/#{total}]"
        puts "Migrated: #{migrated}, Failed: #{failed}, Skipped: #{skipped}"
      end
    end

    puts "\n"
    puts "=" * 60
    puts "Migration complete!"
    puts "Total processed: #{total}"
    puts "Successfully migrated: #{migrated}"
    puts "Failed: #{failed}"
    puts "Skipped (already migrated): #{skipped}"
    puts "=" * 60
  end

  desc "Migrate specific fatwa by ID"
  task :migrate_fatwa, [ :id ] => :environment do |t, args|
    unless args[:id]
      puts "Usage: rake audio:migrate_fatwa[ID]"
      exit 1
    end

    fatwa = Fatwa.find(args[:id])

    unless fatwa.optimized_audio.attached?
      puts "Fatwa ##{fatwa.id} has no optimized_audio attached"
      exit 1
    end

    if fatwa.final_audio.attached?
      puts "Fatwa ##{fatwa.id} already has final_audio attached"
      exit 0
    end

    puts "Migrating Fatwa ##{fatwa.id}: #{fatwa.title}"
    puts "Key: #{fatwa.generate_final_audio_bucket_key}"

    if fatwa.migrate_to_final_audio
      puts "✓ Successfully migrated!"
    else
      puts "✗ Migration failed. Check logs for details."
      exit 1
    end
  end

  desc "Check migration status"
  task migration_status: :environment do
    total_fatwas = Fatwa.count
    with_optimized = Fatwa.joins(:optimized_audio_attachment).distinct.count
    with_final = Fatwa.joins(:final_audio_attachment).distinct.count
    pending = Fatwa.joins(:optimized_audio_attachment).left_joins(:final_audio_attachment)
                   .where(active_storage_attachments_final_audios_fatwas: { id: nil }).distinct.count

    puts "=" * 60
    puts "Audio Migration Status"
    puts "=" * 60
    puts "Total Fatwas: #{total_fatwas}"
    puts "With optimized_audio: #{with_optimized}"
    puts "With final_audio: #{with_final}"
    puts "Pending migration: #{pending}"
    puts "=" * 60
  end
end
