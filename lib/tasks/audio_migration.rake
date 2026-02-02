namespace :audio do
  desc "Migrate optimized_audio to final_audio for all content types (use parallel=true for background jobs)"
  task migrate_to_final: :environment do
    parallel = ENV["parallel"] == "true" || ENV["PARALLEL"] == "true"

    puts "=" * 60
    puts "Starting Audio Migration to final_audio"
    puts "Mode: #{parallel ? 'PARALLEL (Background Jobs)' : 'SYNCHRONOUS'}"
    puts "=" * 60

    if parallel
      # Enqueue jobs for parallel processing
      puts "\n[1/3] Enqueueing Fatwa migration jobs..."
      fatwa_count = enqueue_migration_jobs(Fatwa, "Fatwa")

      puts "\n[2/3] Enqueueing Lesson migration jobs..."
      lesson_count = enqueue_migration_jobs(Lesson, "Lesson")

      puts "\n[3/3] Enqueueing Lecture migration jobs..."
      lecture_count = enqueue_migration_jobs(Lecture, "Lecture")

      puts "\n"
      puts "=" * 60
      puts "Jobs Enqueued Successfully"
      puts "=" * 60
      puts "Fatwas:   #{fatwa_count} jobs"
      puts "Lessons:  #{lesson_count} jobs"
      puts "Lectures: #{lecture_count} jobs"
      puts "TOTAL:    #{fatwa_count + lesson_count + lecture_count} jobs"
      puts "=" * 60
      puts "\nMonitor job progress with your background job system (Sidekiq/Good Job/etc.)"
    else
      # Process synchronously
      puts "\n[1/3] Migrating Fatwas..."
      fatwa_stats = migrate_model(Fatwa, "Fatwa")

      puts "\n[2/3] Migrating Lessons..."
      lesson_stats = migrate_model(Lesson, "Lesson")

      puts "\n[3/3] Migrating Lectures..."
      lecture_stats = migrate_model(Lecture, "Lecture")

      # Summary
      puts "\n"
      puts "=" * 60
      puts "Migration Complete - Summary"
      puts "=" * 60
      print_model_stats("Fatwas", fatwa_stats)
      print_model_stats("Lessons", lesson_stats)
      print_model_stats("Lectures", lecture_stats)

      total_migrated = fatwa_stats[:migrated] + lesson_stats[:migrated] + lecture_stats[:migrated]
      total_failed = fatwa_stats[:failed] + lesson_stats[:failed] + lecture_stats[:failed]
      total_skipped = fatwa_stats[:skipped] + lesson_stats[:skipped] + lecture_stats[:skipped]

      puts "-" * 60
      puts "TOTAL:"
      puts "  Successfully migrated: #{total_migrated}"
      puts "  Failed: #{total_failed}"
      puts "  Skipped: #{total_skipped}"
      puts "=" * 60
    end
  end

  def enqueue_migration_jobs(model_class, model_name)
    count = 0
    scope = model_class.includes(:optimized_audio_attachment, :final_audio_attachment)
    scope = scope.includes(:scholar) if model_class == Fatwa || model_class == Lecture
    scope = scope.includes(series: :scholar) if model_class == Lesson

    scope.find_each do |record|
      next unless record.optimized_audio.attached?
      next if record.final_audio.attached?

      AudioMigrationJob.perform_later(model_name, record.id)
      count += 1
      print "." if count % 50 == 0
    end

    puts " Enqueued #{count} jobs"
    count
  end

  def migrate_model(model_class, model_name)
    stats = { migrated: 0, failed: 0, skipped: 0, total: 0 }

    scope = model_class.includes(:optimized_audio_attachment, :final_audio_attachment)
    scope = scope.includes(:scholar) if model_class == Fatwa || model_class == Lecture
    scope = scope.includes(series: :scholar) if model_class == Lesson

    scope.find_each.with_index do |record, index|
      next unless record.optimized_audio.attached?
      stats[:total] += 1

      if record.final_audio.attached?
        stats[:skipped] += 1
        print "."
        next
      end

      if record.migrate_to_final_audio
        stats[:migrated] += 1
        print "✓"
      else
        stats[:failed] += 1
        print "✗"
      end

      # Progress update every 50 records
      if (index + 1) % 50 == 0
        puts " [#{index + 1}]"
        puts "  Migrated: #{stats[:migrated]}, Failed: #{stats[:failed]}, Skipped: #{stats[:skipped]}"
      end
    end

    puts "\n"
    stats
  end

  def print_model_stats(label, stats)
    puts "#{label}:"
    puts "  Total with audio: #{stats[:total]}"
    puts "  Migrated: #{stats[:migrated]}"
    puts "  Failed: #{stats[:failed]}"
    puts "  Skipped: #{stats[:skipped]}"
  end

  desc "Migrate specific fatwa by ID (use async=true for background job)"
  task :migrate_fatwa, [ :id ] => :environment do |t, args|
    async = ENV["async"] == "true" || ENV["ASYNC"] == "true"
    migrate_single_record(Fatwa, args[:id], "Fatwa", async)
  end

  desc "Migrate specific lesson by ID (use async=true for background job)"
  task :migrate_lesson, [ :id ] => :environment do |t, args|
    async = ENV["async"] == "true" || ENV["ASYNC"] == "true"
    migrate_single_record(Lesson, args[:id], "Lesson", async)
  end

  desc "Migrate specific lecture by ID (use async=true for background job)"
  task :migrate_lecture, [ :id ] => :environment do |t, args|
    async = ENV["async"] == "true" || ENV["ASYNC"] == "true"
    migrate_single_record(Lecture, args[:id], "Lecture", async)
  end

  desc "Enqueue migration jobs for fatwas only"
  task enqueue_fatwas: :environment do
    puts "Enqueueing Fatwa migration jobs..."
    count = enqueue_migration_jobs(Fatwa, "Fatwa")
    puts "✓ Enqueued #{count} Fatwa migration jobs"
  end

  desc "Enqueue migration jobs for lessons only"
  task enqueue_lessons: :environment do
    puts "Enqueueing Lesson migration jobs..."
    count = enqueue_migration_jobs(Lesson, "Lesson")
    puts "✓ Enqueued #{count} Lesson migration jobs"
  end

  desc "Enqueue migration jobs for lectures only"
  task enqueue_lectures: :environment do
    puts "Enqueueing Lecture migration jobs..."
    count = enqueue_migration_jobs(Lecture, "Lecture")
    puts "✓ Enqueued #{count} Lecture migration jobs"
  end

  def migrate_single_record(model_class, id, model_name, async = false)
    unless id
      puts "Usage: rake audio:migrate_#{model_name.downcase}[ID] #{"async=true" if !async}"
      exit 1
    end

    record = model_class.find(id)

    unless record.optimized_audio.attached?
      puts "#{model_name} ##{record.id} has no optimized_audio attached"
      exit 1
    end

    if record.final_audio.attached?
      puts "#{model_name} ##{record.id} already has final_audio attached"
      exit 0
    end

    title = record.respond_to?(:title) ? record.title : record.id
    puts "Migrating #{model_name} ##{record.id}: #{title}"
    puts "Key: #{record.generate_final_audio_bucket_key}"

    if async
      AudioMigrationJob.perform_later(model_name, record.id)
      puts "✓ Migration job enqueued! Check your background job system for progress."
    else
      if record.migrate_to_final_audio
        puts "✓ Successfully migrated!"
      else
        puts "✗ Migration failed. Check logs for details."
        exit 1
      end
    end
  end

  desc "Check migration status for all content types"
  task migration_status: :environment do
    puts "=" * 60
    puts "Audio Migration Status"
    puts "=" * 60

    # Fatwas
    puts "\nFatwas:"
    print_migration_stats(Fatwa)

    # Lessons
    puts "\nLessons:"
    print_migration_stats(Lesson)

    # Lectures
    puts "\nLectures:"
    print_migration_stats(Lecture)

    puts "=" * 60
  end

  def print_migration_stats(model_class)
    total = model_class.count
    with_optimized = model_class.joins(:optimized_audio_attachment).distinct.count
    with_final = model_class.joins(:final_audio_attachment).distinct.count
    pending = with_optimized - with_final

    puts "  Total records: #{total}"
    puts "  With optimized_audio: #{with_optimized}"
    puts "  With final_audio: #{with_final}"
    puts "  Pending migration: #{pending}"
  end
end
