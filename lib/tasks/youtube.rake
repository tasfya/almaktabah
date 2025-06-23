namespace :youtube do
  desc "Download YouTube videos for lessons and lectures that have youtube_url"
  task download_videos: :environment do
    puts "Starting YouTube video downloads..."

    lessons_with_youtube = Lesson.where.not(youtube_url: nil).where(youtube_url: /youtube\.com|youtu\.be/)
    lectures_with_youtube = Lecture.where.not(youtube_url: nil).where(youtube_url: /youtube\.com|youtu\.be/)

    total_count = lessons_with_youtube.count + lectures_with_youtube.count
    processed_count = 0

    puts "Found #{lessons_with_youtube.count} lessons and #{lectures_with_youtube.count} lectures with YouTube URLs"

    if total_count == 0
      puts "No records with YouTube URLs found."
      exit
    end

    # Process lessons
    lessons_with_youtube.find_each do |lesson|
      begin
        if lesson.valid_youtube_url?
          YoutubeDownloadJob.perform_later("Lesson", lesson.id, "video")
          processed_count += 1
          puts "[#{processed_count}/#{total_count}] Queued download job for lesson: #{lesson.title}"
        else
          puts "Invalid YouTube URL for lesson: #{lesson.title} - #{lesson.youtube_url}"
        end
      rescue => e
        puts "Error queuing job for lesson #{lesson.title}: #{e.message}"
      end
    end

    # Process lectures
    lectures_with_youtube.find_each do |lecture|
      begin
        if lecture.valid_youtube_url?
          YoutubeDownloadJob.perform_later("Lecture", lecture.id, "video")
          processed_count += 1
          puts "[#{processed_count}/#{total_count}] Queued download job for lecture: #{lecture.title}"
        else
          puts "Invalid YouTube URL for lecture: #{lecture.title} - #{lecture.youtube_url}"
        end
      rescue => e
        puts "Error queuing job for lecture #{lecture.title}: #{e.message}"
      end
    end

    puts "\nCompleted! Queued #{processed_count} download jobs."
    puts "You can monitor job progress in the Rails console or job dashboard."
  end

  desc "Download YouTube audio only for lessons and lectures"
  task download_audio: :environment do
    puts "Starting YouTube audio-only downloads..."

    lessons_with_youtube = Lesson.where.not(youtube_url: nil).where(youtube_url: /youtube\.com|youtu\.be/)
    lectures_with_youtube = Lecture.where.not(youtube_url: nil).where(youtube_url: /youtube\.com|youtu\.be/)

    total_count = lessons_with_youtube.count + lectures_with_youtube.count
    processed_count = 0

    puts "Found #{lessons_with_youtube.count} lessons and #{lectures_with_youtube.count} lectures with YouTube URLs"

    if total_count == 0
      puts "No records with YouTube URLs found."
      exit
    end

    # Process lessons
    lessons_with_youtube.find_each do |lesson|
      begin
        if lesson.valid_youtube_url?
          YoutubeDownloadJob.perform_later("Lesson", lesson.id, "audio")
          processed_count += 1
          puts "[#{processed_count}/#{total_count}] Queued audio download job for lesson: #{lesson.title}"
        end
      rescue => e
        puts "Error queuing audio job for lesson #{lesson.title}: #{e.message}"
      end
    end

    # Process lectures
    lectures_with_youtube.find_each do |lecture|
      begin
        if lecture.valid_youtube_url?
          YoutubeDownloadJob.perform_later("Lecture", lecture.id, "audio")
          processed_count += 1
          puts "[#{processed_count}/#{total_count}] Queued audio download job for lecture: #{lecture.title}"
        end
      rescue => e
        puts "Error queuing audio job for lecture #{lecture.title}: #{e.message}"
      end
    end

    puts "\nCompleted! Queued #{processed_count} audio download jobs."
  end

  desc "Check status of YouTube downloads"
  task status: :environment do
    puts "YouTube Download Status:"
    puts "=" * 50

    # Count records with YouTube URLs
    lessons_with_youtube = Lesson.where.not(youtube_url: nil)
    lectures_with_youtube = Lecture.where.not(youtube_url: nil)

    # Count records with downloaded videos/audio
    lessons_with_video = lessons_with_youtube.joins(:video_attachment)
    lessons_with_audio = lessons_with_youtube.joins(:audio_attachment)
    lectures_with_video = lectures_with_youtube.joins(:video_attachment)
    lectures_with_audio = lectures_with_youtube.joins(:audio_attachment)

    puts "Lessons:"
    puts "  - With YouTube URLs: #{lessons_with_youtube.count}"
    puts "  - With downloaded videos: #{lessons_with_video.count}"
    puts "  - With downloaded audio: #{lessons_with_audio.count}"
    puts ""
    puts "Lectures:"
    puts "  - With YouTube URLs: #{lectures_with_youtube.count}"
    puts "  - With downloaded videos: #{lectures_with_video.count}"
    puts "  - With downloaded audio: #{lectures_with_audio.count}"
    puts ""

    # Show pending jobs
    pending_jobs = SolidQueue::Job.where(class_name: "YoutubeDownloadJob", finished_at: nil).count
    puts "Pending YouTube download jobs: #{pending_jobs}"
  end

  desc "Retry failed YouTube downloads"
  task retry_failed: :environment do
    puts "Retrying failed YouTube downloads..."

    # Find records with YouTube URLs but no attached files
    lessons_to_retry = Lesson.where.not(youtube_url: nil)
                             .left_joins(:video_attachment, :audio_attachment)
                             .where(active_storage_attachments: { id: nil })

    lectures_to_retry = Lecture.where.not(youtube_url: nil)
                               .left_joins(:video_attachment, :audio_attachment)
                               .where(active_storage_attachments: { id: nil })

    total_retries = lessons_to_retry.count + lectures_to_retry.count

    puts "Found #{lessons_to_retry.count} lessons and #{lectures_to_retry.count} lectures to retry"

    if total_retries == 0
      puts "No failed downloads found to retry."
      exit
    end

    processed = 0

    lessons_to_retry.find_each do |lesson|
      YoutubeDownloadJob.perform_later("Lesson", lesson.id, "video")
      processed += 1
      puts "[#{processed}/#{total_retries}] Retrying lesson: #{lesson.title}"
    end

    lectures_to_retry.find_each do |lecture|
      YoutubeDownloadJob.perform_later("Lecture", lecture.id, "video")
      processed += 1
      puts "[#{processed}/#{total_retries}] Retrying lecture: #{lecture.title}"
    end

    puts "\nQueued #{processed} retry jobs."
  end

  desc "Test YouTube downloader with a sample URL"
  task :test, [ :url ] => :environment do |t, args|
    url = args[:url] || "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

    puts "🎥 Testing YouTube Downloader System"
    puts "=" * 40
    puts "Testing with URL: #{url}"
    puts

    begin
      # Test YoutubeInfoService
      puts "1. Testing YoutubeInfoService..."
      info_service = YoutubeInfoService.new(url: url)

      video_id = info_service.extract_video_id
      puts "   Video ID: #{video_id}"

      thumbnail_url = info_service.get_thumbnail_url
      puts "   Thumbnail URL: #{thumbnail_url}"

      embed_url = info_service.get_embed_url
      puts "   Embed URL: #{embed_url}"

      puts "   Getting video info..."
      info = info_service.get_video_info
      if info
        puts "   ✅ Successfully extracted video info:"
        puts "      Title: #{info['title']}"
        puts "      Author: #{info['author_name']}" if info["author_name"]
        puts "      Duration: #{info['duration']} seconds" if info["duration"]
      else
        puts "   ❌ Failed to extract video info"
      end

      puts

      # Test YoutubeDownloaderService
      puts "2. Testing YoutubeDownloaderService..."
      downloader = YoutubeDownloaderService.new(url: url)

      puts "   Can download files: #{downloader.can_download?}"
      unless downloader.can_download?
        puts "   Installation suggestion: #{downloader.installation_suggestion}"
      end

      puts "   Testing info extraction via downloader..."
      downloader_info = downloader.get_video_info
      if downloader_info
        puts "   ✅ Successfully extracted info via downloader:"
        puts "      Video ID: #{downloader_info['video_id']}"
        puts "      Title: #{downloader_info['title']}" if downloader_info["title"]
      else
        puts "   ❌ Failed to extract info via downloader"
      end

      puts
      puts "🎉 Test completed successfully!"

    rescue => e
      puts "❌ Error during test: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end

  desc "Clean up YouTube-related data and attachments"
  task cleanup: :environment do
    puts "🧹 YouTube Cleanup Utility"
    puts "=" * 40
    puts

    # Show current state
    puts "Current state:"
    lessons_with_youtube = Lesson.where.not(youtube_url: nil)
    lectures_with_youtube = Lecture.where.not(youtube_url: nil)

    lessons_with_video = lessons_with_youtube.joins(:video_attachment)
    lessons_with_audio = lessons_with_youtube.joins(:audio_attachment)
    lectures_with_video = lectures_with_youtube.joins(:video_attachment)
    lectures_with_audio = lectures_with_youtube.joins(:audio_attachment)

    puts "  Lessons with YouTube URLs: #{lessons_with_youtube.count}"
    puts "  Lessons with video files: #{lessons_with_video.count}"
    puts "  Lessons with audio files: #{lessons_with_audio.count}"
    puts "  Lectures with YouTube URLs: #{lectures_with_youtube.count}"
    puts "  Lectures with video files: #{lectures_with_video.count}"
    puts "  Lectures with audio files: #{lectures_with_audio.count}"
    puts

    # Check for failed/stale jobs
    failed_jobs = SolidQueue::Job.where(class_name: "YoutubeDownloadJob", finished_at: nil)
                                 .where("created_at < ?", 1.hour.ago)
    puts "  Stale YouTube download jobs (>1 hour): #{failed_jobs.count}"
    puts

    # Interactive cleanup options
    puts "Cleanup options:"
    puts "1. Remove all YouTube video attachments"
    puts "2. Remove all YouTube audio attachments"
    puts "3. Remove all YouTube attachments (video + audio)"
    puts "4. Clear failed/stale YouTube download jobs"
    puts "5. Reset all youtube_url fields to nil"
    puts "6. Remove orphaned YouTube files from storage"
    puts "7. Full cleanup (all of the above)"
    puts "8. Cancel"
    puts

    print "Choose an option (1-8): "
    choice = STDIN.gets.chomp.to_i

    case choice
    when 1
      puts "Removing video attachments..."
      removed_count = 0

      lessons_with_video.find_each do |lesson|
        lesson.video.purge if lesson.video.attached?
        removed_count += 1
      end

      lectures_with_video.find_each do |lecture|
        lecture.video.purge if lecture.video.attached?
        removed_count += 1
      end

      puts "✅ Removed #{removed_count} video attachments"

    when 2
      puts "Removing audio attachments..."
      removed_count = 0

      lessons_with_audio.find_each do |lesson|
        lesson.audio.purge if lesson.audio.attached?
        removed_count += 1
      end

      lectures_with_audio.find_each do |lecture|
        lecture.audio.purge if lecture.audio.attached?
        removed_count += 1
      end

      puts "✅ Removed #{removed_count} audio attachments"

    when 3
      puts "Removing all YouTube attachments..."
      removed_count = 0

      lessons_with_youtube.find_each do |lesson|
        lesson.video.purge if lesson.video.attached?
        lesson.audio.purge if lesson.audio.attached?
        removed_count += 1
      end

      lectures_with_youtube.find_each do |lecture|
        lecture.video.purge if lecture.video.attached?
        lecture.audio.purge if lecture.audio.attached?
        removed_count += 1
      end

      puts "✅ Removed attachments from #{removed_count} records"

    when 4
      puts "Clearing failed/stale YouTube download jobs..."
      cleared_count = failed_jobs.destroy_all.count
      puts "✅ Cleared #{cleared_count} stale jobs"

    when 5
      puts "⚠️  WARNING: This will remove all YouTube URLs from lessons and lectures!"
      print "Are you sure? (y/N): "
      confirm = STDIN.gets.chomp.downcase

      if confirm == "y" || confirm == "yes"
        puts "Clearing YouTube URLs..."
        lessons_updated = Lesson.where.not(youtube_url: nil).update_all(youtube_url: nil)
        lectures_updated = Lecture.where.not(youtube_url: nil).update_all(youtube_url: nil)
        puts "✅ Cleared YouTube URLs from #{lessons_updated} lessons and #{lectures_updated} lectures"
      else
        puts "❌ Cancelled"
      end

    when 6
      puts "Removing orphaned YouTube files from storage..."
      # This will purge any attachments not linked to existing records
      orphaned_count = 0

      ActiveStorage::Blob.where("filename LIKE ?", "%youtube%").find_each do |blob|
        if blob.attachments.empty?
          blob.purge
          orphaned_count += 1
        end
      end

      puts "✅ Removed #{orphaned_count} orphaned files"

    when 7
      puts "⚠️  WARNING: This will perform a FULL cleanup of all YouTube-related data!"
      puts "This includes:"
      puts "  - All video and audio attachments"
      puts "  - All YouTube URLs"
      puts "  - All failed jobs"
      puts "  - All orphaned files"
      puts
      print "Are you absolutely sure? (y/N): "
      confirm = STDIN.gets.chomp.downcase

      if confirm == "y" || confirm == "yes"
        puts "Performing full cleanup..."

        # Remove attachments
        total_removed = 0
        lessons_with_youtube.find_each do |lesson|
          lesson.video.purge if lesson.video.attached?
          lesson.audio.purge if lesson.audio.attached?
          total_removed += 1
        end

        lectures_with_youtube.find_each do |lecture|
          lecture.video.purge if lecture.video.attached?
          lecture.audio.purge if lecture.audio.attached?
          total_removed += 1
        end

        # Clear URLs
        lessons_updated = Lesson.where.not(youtube_url: nil).update_all(youtube_url: nil)
        lectures_updated = Lecture.where.not(youtube_url: nil).update_all(youtube_url: nil)

        # Clear jobs
        jobs_cleared = SolidQueue::Job.where(class_name: "YoutubeDownloadJob").destroy_all.count

        # Remove orphaned files
        orphaned_count = 0
        ActiveStorage::Blob.where("filename LIKE ?", "%youtube%").find_each do |blob|
          if blob.attachments.empty?
            blob.purge
            orphaned_count += 1
          end
        end

        puts "✅ Full cleanup completed:"
        puts "  - Removed attachments from #{total_removed} records"
        puts "  - Cleared URLs from #{lessons_updated} lessons and #{lectures_updated} lectures"
        puts "  - Cleared #{jobs_cleared} jobs"
        puts "  - Removed #{orphaned_count} orphaned files"
      else
        puts "❌ Cancelled"
      end

    when 8
      puts "❌ Cleanup cancelled"

    else
      puts "❌ Invalid option selected"
    end

    puts
    puts "🏁 Cleanup completed!"
  end
end
