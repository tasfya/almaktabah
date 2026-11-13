# frozen_string_literal: true

require "rails_helper"

# Records a Telegram import creates are unpublished and must stay out of every
# public surface, even when the after-save callback assigns them to the site
# (global default domain and scholar default domain both set here).
RSpec.describe "Telegram import visibility", type: :request do
  include ActiveJob::TestHelper
  include_context "with tenant domain"
  let(:tenant_domain_attributes) do
    { is_default: true, podcast_enabled: true, podcast_title: "Feed", podcast_author: "A", podcast_owner_email: "a@example.com" }
  end

  let!(:scholar) { create(:scholar, default_domain: domain) }
  let(:manifest) { telegram_fixture_manifest(scholar: scholar) }
  let(:files_dir) { telegram_fixture_files(manifest) }
  let(:lessons) { TelegramImportRecord.created_records.where(record_type: "Lesson").map(&:record) }
  let(:series) { TelegramImportRecord.created_records.where(record_type: "Series").map(&:record) }
  let(:books) { TelegramImportRecord.created_records.where(record_type: "Book").map(&:record) }

  before do
    TelegramImport::LibraryImporter.new(manifest: manifest, files_dir: files_dir, dry_run: false, io: StringIO.new).call
    # What the audio optimization and duration jobs add in production, unpublished or not.
    lessons.each do |lesson|
      lesson.final_audio.attach(io: Rails.root.join("spec/files/audio.mp3").open, filename: "#{lesson.position}.mp3")
      lesson.update_columns(duration: 60)
    end
  end

  after { FileUtils.rm_rf(files_dir) }

  it "is assigned to the site, which is the case under test" do
    expect(series + lessons + books).to all(satisfy { _1.domains.include?(domain) })
  end

  it "404s every imported lesson, series and book page" do
    lessons.each do |lesson|
      get series_lesson_path(scholar, lesson.series, lesson)
      expect(response).to have_http_status(:not_found)
    end
    series.each do |record|
      get series_path(scholar, record)
      expect(response).to have_http_status(:not_found)
    end
    books.each do |book|
      get book_path(book.scholar, book)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "404s the play page of imported lessons" do
    get play_path("lesson", lessons.first.id)
    expect(response).to have_http_status(:not_found)
  end

  it "keeps imported records out of the sitemaps" do
    %w[lessons series books].each do |type|
      get sitemap_content_path(type: type)
      ids_and_slugs = (lessons.map { "/#{_1.id}" } + (series + books).map(&:slug))
      expect(sitemap_locs).to all(satisfy { |loc| ids_and_slugs.none? { loc.end_with?(_1) } })
    end
  end

  it "keeps imported lessons out of the podcast feed" do
    get "/podcasts/feed"
    expect(response).to have_http_status(:ok)
    lessons.each { expect(response.body).not_to include(_1.title) }
  end

  it "keeps imported lessons out of the video download queue" do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:api, :download_token).and_return("t")

    get "/api/lessons/pending_downloads", headers: { "Authorization" => "Bearer t" }

    expect(response.parsed_body["lessons"].map { _1["id"] }).not_to include(*lessons.map(&:id))
  end
end
