require "rails_helper"

RSpec.describe TelegramImport::ScheduleParser do
  let(:config) { YAML.load_file(file_fixture("telegram_import/config.yml")) }
  let(:rows) do
    described_class.new(file_fixture("telegram_import/schedule_sample.txt").read,
                        texts: config["texts"], start_year: 2025).rows
  end
  let(:lessons) { rows.select { _1["kind"] == "lesson" } }
  let(:exams) { rows.select { _1["kind"] == "exam" } }

  it "parses lesson rows despite the PDF's mangled Arabic" do
    expect(lessons.first(2)).to eq([
      { "kind" => "lesson", "text_key" => "wajibuna", "n" => 1, "date" => Date.new(2025, 11, 8) },
      { "kind" => "lesson", "text_key" => "qawaid", "n" => 1, "date" => Date.new(2025, 11, 9) }
    ])
  end

  it "moves to the next year when the month goes down" do
    expect(lessons.last).to include("text_key" => "qawaid", "n" => 4, "date" => Date.new(2026, 1, 3))
  end

  it "reads a right-to-left exam window as opens → closes and finds every text it covers" do
    expect(exams.first).to include("text_keys" => %w[wajibuna qawaid usul_sitta], "range" => nil,
                                   "opens_on" => Date.new(2025, 11, 19), "closes_on" => Date.new(2025, 11, 21))
  end

  it "parses a Monday→Thursday window and a lesson range" do
    expect(exams.last).to include("text_keys" => %w[usul_sitta], "range" => [ 1, 3 ],
                                  "opens_on" => Date.new(2026, 1, 5), "closes_on" => Date.new(2026, 1, 8))
  end

  it "keeps breaks in order" do
    expect(rows.map { _1["kind"] }).to eq(%w[lesson] * 7 + %w[exam break lesson exam])
  end
end
