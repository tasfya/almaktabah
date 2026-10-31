# frozen_string_literal: true

require "rails_helper"

RSpec.describe MimhamImportService do
  let(:scholar_name) { "محمد بن هادي" }

  def import(**options)
    described_class.new(csv_file: file_fixture("mimham/lectures.csv").to_s, **options).import
  end

  context "when importing" do
    it "creates the scholar and a lecture per row with a title" do
      result = nil

      expect { result = import }.to change(Lecture, :count).by(3).and change(Scholar, :count).by(1)
      expect(result).to include(created_count: 3, skipped_count: 1, existing_count: 0, scholars_created: 1, errors: [])
      expect(Scholar.last.full_name).to eq(scholar_name)
      expect(Lecture.find_by(source_url: "https://mimham.example/lectures/1")).to have_attributes(
        title: "خطبة جديدة", kind: "sermon", category: "خطب", published_at: Time.zone.parse("2024-01-05"), scholar: Scholar.last
      )
    end

    it "queues an audio download for a row with an audio_url" do
      expect { import }.to have_enqueued_job(MimhamAudioDownloadJob).once
        .with("Lecture", kind_of(Integer), "https://cdn.mimham.example/1.mp3")
    end

    it "does not queue an audio download when download_audio is off" do
      expect { import(download_audio: false) }.not_to have_enqueued_job(MimhamAudioDownloadJob)
    end

    it "uses an existing scholar matched by full name" do
      scholar = create(:scholar, full_name: scholar_name, created_at: 1.day.ago)

      result = import

      expect(result[:scholars_created]).to eq(0)
      expect(scholar.lectures.count).to eq(3)
    end

    it "uses an existing scholar matched by full_name_alias" do
      scholar = create(:scholar, full_name: "Muhammad ibn Hadi", full_name_alias: scholar_name)

      expect { import }.not_to change(Scholar, :count)
      expect(scholar.lectures.count).to eq(3)
    end

    it "uses an existing scholar whose full name contains the given name" do
      scholar = create(:scholar, full_name: "الشيخ #{scholar_name} المدخلي")

      expect { import }.not_to change(Scholar, :count)
      expect(scholar.lectures.count).to eq(3)
    end

    it "skips a row whose source_url is already imported" do
      existing = create(:lecture, source_url: "https://mimham.example/lectures/2")

      result = import

      expect(result[:existing_records]).to contain_exactly(a_hash_including(title: "خطبة موجودة", existing_id: existing.id))
      expect(result[:skipped_count]).to eq(2)
    end

    it "creates nothing when the same file is imported again" do
      import

      result = nil
      expect { result = import }.not_to change(Lecture, :count)
      expect(result).to include(created_count: 0, existing_count: 3, skipped_count: 4, errors: [])
    end
  end

  context "with dry_run" do
    it "lists every row with a title as new without creating anything" do
      result = nil

      expect { result = import(dry_run: true) }.not_to change { [ Lecture.count, Scholar.count ] }
      expect(result).to include(dry_run: true, created_count: 0, would_create_count: 3, errors: [])
      expect(result[:new_records].pluck(:title)).to eq([ "خطبة جديدة", "خطبة موجودة", "بدون رابط" ])
    end

    it "lists a row without source_url as existing when the scholar already has that title" do
      create(:lecture, title: "بدون رابط", scholar: create(:scholar, full_name: scholar_name))

      result = import(dry_run: true)

      expect(result[:existing_records].pluck(:title)).to eq([ "بدون رابط" ])
    end
  end

  it "accepts an IO as well as a path" do
    result = file_fixture("mimham/lectures.csv").open { |file| described_class.new(csv_file: file, dry_run: true).import }

    expect(result[:would_create_count]).to eq(3)
  end

  it "rejects a CSV missing required columns" do
    result = described_class.new(csv_file: file_fixture("mimham/series.csv").to_s).import

    expect(result[:errors]).to eq([ "CSV missing required columns: kind" ])
  end

  it "reports a missing file" do
    expect(described_class.new(csv_file: nil).import[:errors]).to eq([ "No CSV file provided" ])
  end

  it "prints a report" do
    service = described_class.new(csv_file: file_fixture("mimham/lectures.csv").to_s, dry_run: true)
    service.import

    expect { service.print_report }.to output(/DRY RUN REPORT.*New records:\s+3.*خطبة جديدة/m).to_stdout
  end
end
