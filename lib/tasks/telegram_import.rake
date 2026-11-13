namespace :telegram_import do
  desc "Build the import manifest from a tdl export and the schedule PDF text. " \
       "ENV: EXPORT, SCHEDULE, CONFIG (default config/imports/mtoon_altawheed.yml), OUT (default data/imports/mtoon_altawheed/manifest.json)"
  task manifest: :environment do
    out = ENV.fetch("OUT", "data/imports/mtoon_altawheed/manifest.json")
    manifest = TelegramImport::ManifestBuilder.new(
      export_path: ENV.fetch("EXPORT"),
      schedule_path: ENV.fetch("SCHEDULE"),
      config_path: ENV.fetch("CONFIG", "config/imports/mtoon_altawheed.yml")
    ).call
    FileUtils.mkdir_p(File.dirname(out))
    File.write(out, JSON.pretty_generate(manifest) + "\n")

    texts = manifest["texts"]
    schedule = manifest["schedule"].group_by { _1["kind"] }
    puts "lessons per text: #{texts.to_h { [ _1['key'], _1['lessons'].size ] }}"
    puts "lessons #{texts.sum { _1['lessons'].size }}, matn #{texts.size}, transcripts #{texts.sum { _1['transcripts'].size }}"
    puts "schedule: #{schedule.transform_values(&:size)}"
    manifest["warnings"].each { puts "warning: #{_1}" }
    puts "wrote #{out}"
  end
end

namespace :telegram_import do
  desc "Import the manifest's lessons and books (unpublished). Dry run unless DRY_RUN=0. " \
       "ENV: MANIFEST, FILES_DIR (required for a real run), ONLY=key,key, DRY_RUN"
  task library: :environment do
    manifest = JSON.parse(File.read(ENV.fetch("MANIFEST", "data/imports/mtoon_altawheed/manifest.json")))
    TelegramImport::LibraryImporter.new(
      manifest: manifest,
      files_dir: ENV["FILES_DIR"].presence,
      only: ENV.fetch("ONLY", "").split(","),
      dry_run: ENV.fetch("DRY_RUN", "1") != "0"
    ).call
  end
end
