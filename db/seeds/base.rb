require 'open-uri'
require 'fileutils'
require 'json'

module Seeds
  class Base
    def self.create_storage_directories
      %w[books covers audio].each do |dir|
        FileUtils.mkdir_p(Rails.root.join('storage', dir))
      end
    end

    def self.download_file(url, destination_path, base_url = "https://mohammed-ramzan.com")
  return nil if url.blank?

  full_url = url.start_with?('http') ? url : "#{base_url}/#{url}"
  FileUtils.mkdir_p(File.dirname(destination_path))
  return destination_path if File.exist?(destination_path)

  URI.open(full_url,
           content_length_proc: ->(length) {
             if length && length > 0
               @download_progress = ProgressBar.create(
                 title: "⬇ Downloading #{File.basename(destination_path)}",
                 total: length,
                 format: "%t |%B| %p%% (%c/%C bytes)",
                 progress_mark: '▓',
                 remainder_mark: '░'
               )
             end
           },
           progress_proc: ->(size) {
             @download_progress&.progress = size
           }) do |file|
    File.open(destination_path, 'wb') do |output|
      output.write(file.read)
    end
  end

  @download_progress&.finish
  destination_path
rescue => e
  puts "Download failed (#{url}): #{e.message}"
  nil
end


    def self.load_json(file_path)
      JSON.parse(File.read(Rails.root.join(file_path)))
    end
  end
end
