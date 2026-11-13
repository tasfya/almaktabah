require "rails_helper"

RSpec.describe TelegramImportRecord, type: :model do
  let(:lesson) { create(:lesson) }

  def record!(external_id: "message:1", outcome: "created")
    described_class.create!(source: "t.me/x", external_id: external_id, record: lesson, outcome: outcome)
  end

  it "rejects a second row with the same source and external_id at the DB level" do
    record!
    duplicate = described_class.new(source: "t.me/x", external_id: "message:1", record: lesson, outcome: "created")
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "finds the mapped record" do
    record!
    expect(described_class.lookup("t.me/x", "message:1")).to eq(lesson)
    expect(described_class.lookup("t.me/x", "message:2")).to be_nil
  end

  it "accepts only created or linked outcomes" do
    expect { record!(outcome: "updated") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
