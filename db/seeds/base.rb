require 'open-uri'
require 'fileutils'
require 'json'

module Seeds
  class Base
    def self.create_storage_directories
      %w[books covers audio video].each do |dir|
        FileUtils.mkdir_p(Rails.root.join('storage', dir))
        FileUtils.mkdir_p(Rails.root.join('storage', dir, 'lectures'))
        FileUtils.mkdir_p(Rails.root.join('storage', dir, 'lessons'))
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

    def self.default_scholar
      @default_scholar ||= Scholar.find_or_create_by(
        first_name: "محمد",
        last_name: "بن رمزان الهاجري"
      )
    end

    def self.assign_to_domain(record, domain_id)
      return unless domain_id

      # Directly create the domain assignment without querying the domain
      record.domain_assignments.find_or_create_by!(domain_id: domain_id)
    end
  end
end
