require "rails_helper"

RSpec.describe CohortSlot, type: :model do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }

  it "has one slot per item in a cohort" do
    slot = create(:cohort_slot)
    duplicate = build(:cohort_slot, cohort: slot.cohort, program_item: slot.program_item)
    expect(duplicate).not_to be_valid
  end

  it "requires an item of the cohort's program" do
    expect(build(:cohort_slot, program_item: create(:program_item))).not_to be_valid
  end

  it "requires a window for an exam" do
    slot = build(:cohort_slot, :exam, opens_at: nil, closes_at: Time.current)
    expect(slot).not_to be_valid
  end

  it "requires the window to close after it opens" do
    slot = build(:cohort_slot, :exam)
    slot.closes_at = slot.opens_at
    expect(slot).not_to be_valid
  end

  it "is destroyed with its program item" do
    slot = create(:cohort_slot)
    expect { slot.program_item.destroy! }.to change(CohortSlot, :count).by(-1)
  end

  describe "exam window, in the cohort time zone" do
    subject(:slot) do
      build(:cohort_slot, :exam, opens_at: riyadh.local(2025, 11, 19, 0, 0), closes_at: riyadh.local(2025, 11, 21, 22, 0))
    end

    it "is open at 21:59 Riyadh on the closing day and closed at 22:00" do
      expect(slot.open?(riyadh.local(2025, 11, 21, 21, 59))).to be(true)
      expect(slot.closed?(riyadh.local(2025, 11, 21, 21, 59))).to be(false)
      expect(slot.open?(Time.utc(2025, 11, 21, 19, 0))).to be(false)
      expect(slot.closed?(Time.utc(2025, 11, 21, 19, 0))).to be(true)
    end

    it "opens at midnight Riyadh, not midnight UTC" do
      expect(slot.open?(riyadh.local(2025, 11, 18, 23, 59))).to be(false)
      expect(slot.closed?(riyadh.local(2025, 11, 18, 23, 59))).to be(false)
      expect(slot.open?(riyadh.local(2025, 11, 19, 0, 0))).to be(true)
    end
  end
end
