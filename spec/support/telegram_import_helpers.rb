# frozen_string_literal: true

# Builds the fixture import manifest (spec/fixtures/files/telegram_import) and a
# files directory laid out like scripts/telegram/download_mtoon_media.sh output.
module TelegramImportHelpers
  def telegram_fixture_manifest(scholar:)
    TelegramImport::ManifestBuilder.new(
      export_path: file_fixture("telegram_import/export_sample.json").to_s,
      schedule_path: file_fixture("telegram_import/schedule_sample.txt").to_s,
      config_path: file_fixture("telegram_import/config.yml").to_s
    ).call.merge("scholar_id" => scholar.id)
  end

  def telegram_fixture_files(manifest, skip: [])
    dir = Pathname(Dir.mktmpdir("telegram_import", Rails.root.join("tmp")))
    manifest["texts"].each do |text|
      text["lessons"].each do |lesson|
        next if skip.include?(lesson["audio_message_id"])

        FileUtils.cp(Rails.root.join("spec/files/audio.mp3"), dir.join("#{lesson['audio_message_id']}_#{lesson['audio_file']}"))
      end
      [ text["matn"], *text["transcripts"] ].each do |book|
        next if skip.include?(book["message_id"])

        FileUtils.cp(Rails.root.join("spec/files/sample.pdf"), dir.join("#{book['message_id']}_#{book['file']}"))
      end
    end
    dir
  end
end

RSpec.configure { |config| config.include TelegramImportHelpers }
