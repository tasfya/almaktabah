namespace :db do
  desc "Backup the SQLite database"
  task backup: :environment do
    # Get database configuration
    db_config = Rails.application.config.database_configuration[Rails.env]
    db_file = db_config["primary"]["database"]

    # Resolve relative paths
    db_file = File.expand_path(db_file, Rails.root) unless Pathname.new(db_file).absolute?

    # Check if database file exists
    unless File.exist?(db_file)
      puts "Database file not found: #{db_file}"
      exit 1
    end

    # Create backup directory if it doesn't exist
    backup_dir = File.join(Rails.root, "storage", "backups")
    FileUtils.mkdir_p(backup_dir)

    # Create backup filename
    timestamp = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    backup_file = File.join(backup_dir, "#{Rails.env}_backup_#{timestamp}.sqlite3")

    begin
      # Create backup using sqlite3 command
      system("sqlite3 \"#{db_file}\" \".backup '#{backup_file}'\"")

      # Check if backup was successful
      if $?.success? && File.exist?(backup_file)
        puts "Database backed up successfully to #{backup_file}"
        puts "Backup size: #{File.size(backup_file)} bytes"
      else
        puts "Backup failed!"
        exit 1
      end
    rescue => e
      puts "Error creating backup: #{e.message}"
      exit 1
    end
  end

  desc "Restore SQLite database from backup"
  task :load_backup, [ :backup_file ] => :environment do |t, args|
    # Get database configuration
    db_config = Rails.application.config.database_configuration[Rails.env]
    db_file = db_config["primary"]["database"]

    # Resolve relative paths
    db_file = File.expand_path(db_file, Rails.root) unless Pathname.new(db_file).absolute?

    # Handle backup file argument
    backup_file = args[:backup_file]

    if backup_file.nil?
      # If no backup file specified, list available backups and ask user to choose
      backup_dir = File.join(Rails.root, "storage", "backups")

      unless Dir.exist?(backup_dir)
        puts "No backup directory found at #{backup_dir}"
        exit 1
      end

      backup_files = Dir.glob(File.join(backup_dir, "*.sqlite3")).sort.reverse

      if backup_files.empty?
        puts "No backup files found in #{backup_dir}"
        exit 1
      end

      puts "Available backup files:"
      backup_files.each_with_index do |file, index|
        file_size = File.size(file)
        file_time = File.mtime(file).strftime("%Y-%m-%d %H:%M:%S")
        puts "#{index + 1}. #{File.basename(file)} (#{file_size} bytes, #{file_time})"
      end

      print "Enter the number of the backup to restore (or 'q' to quit): "
      choice = STDIN.gets.chomp

      if choice.downcase == "q"
        puts "Restore cancelled."
        exit 0
      end

      choice_index = choice.to_i - 1
      if choice_index < 0 || choice_index >= backup_files.size
        puts "Invalid choice."
        exit 1
      end

      backup_file = backup_files[choice_index]
    else
      # If backup file is specified, check if it's a full path or just filename
      unless File.exist?(backup_file)
        # Try looking in the backups directory
        backup_dir = File.join(Rails.root, "storage", "backups")
        potential_backup = File.join(backup_dir, backup_file)

        if File.exist?(potential_backup)
          backup_file = potential_backup
        else
          puts "Backup file not found: #{backup_file}"
          exit 1
        end
      end
    end

    # Confirm restoration
    puts "\nThis will replace the current database with the backup:"
    puts "Current database: #{db_file}"
    puts "Backup file: #{backup_file}"
    puts "Backup size: #{File.size(backup_file)} bytes"
    puts "Backup created: #{File.mtime(backup_file).strftime('%Y-%m-%d %H:%M:%S')}"

    print "\nAre you sure you want to continue? (y/N): "
    confirmation = STDIN.gets.chomp

    unless confirmation.downcase == "y"
      puts "Restore cancelled."
      exit 0
    end

    begin
      # Create a backup of current database before restoring
      current_backup = "#{db_file}.pre_restore_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"
      FileUtils.cp(db_file, current_backup)
      puts "Current database backed up to: #{current_backup}"

      # Restore from backup
      FileUtils.cp(backup_file, db_file)

      puts "Database restored successfully from #{backup_file}"
      puts "Previous database saved as: #{current_backup}"

    rescue => e
      puts "Error restoring database: #{e.message}"

      # Try to restore the original if something went wrong
      if File.exist?(current_backup)
        FileUtils.cp(current_backup, db_file)
        puts "Original database restored due to error."
      end

      exit 1
    end
  end

  desc "List available database backups"
  task list_backups: :environment do
    backup_dir = File.join(Rails.root, "storage", "backups")

    unless Dir.exist?(backup_dir)
      puts "No backup directory found at #{backup_dir}"
      exit 1
    end

    backup_files = Dir.glob(File.join(backup_dir, "*.sqlite3")).sort.reverse

    if backup_files.empty?
      puts "No backup files found in #{backup_dir}"
    else
      puts "Available backup files:"
      backup_files.each do |file|
        file_size = File.size(file)
        file_time = File.mtime(file).strftime("%Y-%m-%d %H:%M:%S")
        puts "- #{File.basename(file)} (#{file_size} bytes, #{file_time})"
      end
    end
  end
end
