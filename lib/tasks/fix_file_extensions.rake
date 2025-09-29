namespace :fix do
  desc "Fix file extensions for attachment filenames. Pass dry_run=true to preview changes."
  task :fix_attachments, [ :dry_run ] => :environment do |t, args|
    dry_run = args[:dry_run] == "true"
    puts "Starting to fix attachment filenames... (dry_run: #{dry_run})"

    ActiveStorage::Blob.find_each do |blob|
      original_filename = blob.filename.to_s

      if File.extname(original_filename).empty? || original_filename.end_with?(".")
        ext = case blob.content_type
        when "audio/mpeg", "audio/mp3" then ".mp3"
        when "audio/wav" then ".wav"
        when "audio/ogg" then ".ogg"
        when "video/mp4" then ".mp4"
        when "video/webm" then ".webm"
        when "image/jpeg" then ".jpg"
        when "image/png" then ".png"
        when "image/gif" then ".gif"
        when "application/pdf" then ".pdf"
        else ".bin" # fallback extension
        end

        # Clean up filename ending with a dot
        cleaned_filename = original_filename.chomp(".")
        new_filename = cleaned_filename + ext

        if dry_run
          puts "[DRY RUN] Would update filename for blob #{blob.id}: #{original_filename} -> #{new_filename}"
        else
          blob.update(filename: new_filename)
          puts "Updated filename for blob #{blob.id}: #{original_filename} -> #{new_filename}"
        end
      end
    end

    puts "Finished fixing attachment filenames."
  end
end
