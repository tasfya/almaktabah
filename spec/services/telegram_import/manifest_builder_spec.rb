require "rails_helper"

RSpec.describe TelegramImport::ManifestBuilder do
  let(:config_path) { file_fixture("telegram_import/config.yml").to_s }
  let(:manifest) do
    described_class.new(export_path: file_fixture("telegram_import/export_sample.json").to_s,
                        schedule_path: file_fixture("telegram_import/schedule_sample.txt").to_s,
                        config_path: config_path).call
  end
  let(:texts) { manifest["texts"].index_by { _1["key"] } }
  let(:exams) { manifest["schedule"].select { _1["kind"] == "exam" } }

  it "takes the current-cycle triplet and falls back to the previous cycle for a missing lesson" do
    expect(texts["qawaid"]["lessons"].map { _1["message_id"] }).to eq([ 107, 110, 113 ])
    expect(texts["usul_sitta"]["lessons"].map { _1["message_id"] }).to eq([ 118, 121, 63 ])
  end

  it "records each lesson's audio message, cleaned title and video id" do
    expect(texts["usul_sitta"]["lessons"].first).to include(
      "n" => 1, "audio_message_id" => 119, "audio_file" => "001.mp3",
      "video_id" => "BBBBBBBBBB1", "title" => "شرح الأصول الستة (1)", "posted_on" => "2025-11-15"
    )
  end

  it "normalises every YouTube form to a video id" do
    expect(texts["qawaid"]["lessons"].map { _1["video_id"] }).to eq(%w[AAAAAAAAAA1 AAAAAAAAAA2 AAAAAAAAAA3])
  end

  it "picks the matn and the transcripts with their lesson ranges" do
    expect(texts["qawaid"]["matn"]).to eq("message_id" => 106, "file" => "متن القواعد الأربع.pdf", "title" => "متن القواعد الأربع")
    expect(texts["qawaid"]["transcripts"]).to eq([
      { "message_id" => 116, "file" => "شرح القواعد الأربع.pdf", "title" => "تفريغ شرح القواعد الأربع", "from" => 1, "to" => 3 }
    ])
  end

  it "fills uncovered transcript ranges from the previous cycle, applying title overrides" do
    expect(texts["usul_sitta"]["transcripts"].map { _1.slice("message_id", "title", "from", "to") }).to eq([
      { "message_id" => 125, "title" => "تفريغ شرح الأصول الستة من الدرس 1 إلى 2", "from" => 1, "to" => 2 },
      { "message_id" => 66, "title" => "تفريغ شرح الأصول الستة الدرس 3", "from" => 3, "to" => 3 }
    ])
  end

  it "uses the announced exam window and keeps the PDF's for reference" do
    expect(exams.first).to include(
      "index" => 1, "title" => "اختبار واجبنا نحو ما أمرنا الله به، القواعد الأربع، الأصول الستة",
      "after" => { "text_key" => "usul_sitta", "n" => 3 }, "window_source" => "announced",
      "opens_at" => "2025-11-19T12:03:00+03:00", "closes_at" => "2025-11-25T22:00:00+03:00",
      "pdf_opens_on" => "2025-11-19", "pdf_closes_on" => "2025-11-21", "announcement_message_id" => 124
    )
  end

  it "falls back to the PDF window, 00:00 → 22:00 Riyadh, for an exam not announced yet" do
    expect(exams.last).to include("window_source" => "pdf", "title" => "اختبار الأصول الستة: من الدرس 1 إلى 3",
                                  "opens_at" => "2026-01-05T00:00:00+03:00", "closes_at" => "2026-01-08T22:00:00+03:00")
  end

  it "never puts a form link in the manifest" do
    expect(JSON.dump(manifest)).not_to include("docs.google.com")
  end

  it "drops a schedule row without a recording and warns" do
    expect(manifest["schedule"]).not_to include(a_hash_including("text_key" => "qawaid", "n" => 4))
    expect(manifest["warnings"]).to eq([ "schedule row qawaid 4 (2026-01-03) has no recording; dropped" ])
  end

  context "with an edited export" do
    let(:export) { JSON.parse(file_fixture("telegram_import/export_sample.json").read) }
    let(:export_path) { Rails.root.join("tmp/telegram_import_export_#{Process.pid}.json").to_s }
    let(:manifest) do
      File.write(export_path, JSON.dump(export))
      described_class.new(export_path: export_path, schedule_path: file_fixture("telegram_import/schedule_sample.txt").to_s,
                          config_path: config_path).call
    end

    after { FileUtils.rm_f(export_path) }

    it "never gives a caption without files the next lesson's audio and link" do
      export["messages"].reject! { [ 111, 112 ].include?(_1["id"]) }
      export["messages"].each { _1["id"] -= 2 if (113..115).cover?(_1["id"]) }

      expect { manifest }.to raise_error(described_class::Error, "no complete recording for: qawaid 2")
    end

    it "raises when an exam post does not open on the PDF's date" do
      export["messages"].find { _1["id"] == 124 }["date"] = Time.new(2025, 11, 26, 12, 0, 0, "+03:00").to_i

      expect { manifest }.to raise_error(described_class::Error, /exam 1: .* from 2025-11-19 but post 124 .* on 2025-11-26/)
    end
  end

  context "when a text has fewer recordings than expected" do
    let(:config_path) do
      config = YAML.load_file(file_fixture("telegram_import/config.yml"))
      config["texts"][1]["expected_lessons"] = 5
      Rails.root.join("tmp/telegram_import_config_#{Process.pid}.yml").tap { File.write(_1, config.to_yaml) }.to_s
    end

    after { FileUtils.rm_f(config_path) }

    it "raises and names the missing lessons" do
      expect { manifest }.to raise_error(described_class::Error, "no complete recording for: qawaid 4, qawaid 5")
    end
  end
end
