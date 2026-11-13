require "rails_helper"

RSpec.describe Programs::ReminderDispatchJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:new_york) { Time.find_zone("America/New_York") }
  let(:confirmed) { { confirmed_at: Time.current } }
  let!(:riyadh_enrollment) { create(:enrollment, cohort: create(:cohort), learner: create(:learner, **confirmed)) }
  let!(:ny_enrollment) do
    create(:enrollment, cohort: create(:cohort, time_zone: "America/New_York"), learner: create(:learner, **confirmed))
  end

  def lesson_on(cohort, date)
    create(:cohort_slot, cohort: cohort, program_item: create(:program_item, :lesson, program: cohort.program), available_on: date)
  end

  before do
    [ Date.new(2025, 11, 19), Date.new(2025, 11, 20) ].each { |date| lesson_on(riyadh_enrollment.cohort, date) }
    [ Date.new(2025, 11, 1), Date.new(2025, 11, 3) ].each { |date| lesson_on(ny_enrollment.cohort, date) }
  end

  def dispatched_at(time)
    clear_enqueued_jobs
    travel_to(time) { described_class.perform_now }
    enqueued_jobs.select { |job| job["job_class"] == "Programs::ReminderJob" }.map { |job| job["arguments"] }
  end

  describe "with learner mail on" do
    include_context "with learner mail on"

    it "enqueues a Riyadh cohort at 06:05 Riyadh, not at 05:05" do
      expect(dispatched_at(riyadh.local(2025, 11, 19, 5, 5))).not_to include([ riyadh_enrollment.id, "2025-11-19" ])
      expect(dispatched_at(riyadh.local(2025, 11, 19, 6, 5))).to eq([ [ riyadh_enrollment.id, "2025-11-19" ] ])
    end

    it "catches up a missed 06:05 tick at 09:05 but not at 12:05" do
      expect(dispatched_at(riyadh.local(2025, 11, 19, 9, 5))).to include([ riyadh_enrollment.id, "2025-11-19" ])
      expect(dispatched_at(riyadh.local(2025, 11, 19, 12, 5))).to be_empty
    end

    it "uses each cohort's own zone, across a DST change" do
      expect(dispatched_at(new_york.local(2025, 11, 3, 6, 5))).to eq([ [ ny_enrollment.id, "2025-11-03" ] ])
      expect(dispatched_at(new_york.local(2025, 11, 1, 6, 5))).to eq([ [ ny_enrollment.id, "2025-11-01" ] ])
      expect(dispatched_at(new_york.local(2025, 11, 3, 5, 5))).to be_empty
    end

    it "enqueues nothing for a cohort with nothing to say today" do
      expect(dispatched_at(riyadh.local(2025, 11, 21, 6, 5))).to be_empty
    end

    it "enqueues for an exam closing before the next reminder on a day without lessons" do
      item = create(:program_item, :exam, program: riyadh_enrollment.cohort.program)
      create(:cohort_slot, cohort: riyadh_enrollment.cohort, program_item: item, available_on: Date.new(2025, 11, 18),
        opens_at: riyadh.local(2025, 11, 18), closes_at: riyadh.local(2025, 11, 21, 22))

      expect(dispatched_at(riyadh.local(2025, 11, 21, 6, 5))).to eq([ [ riyadh_enrollment.id, "2025-11-21" ] ])
    end

    it "does nothing while learner accounts are switched off" do
      Rails.configuration.x.learners_enabled = false

      expect(dispatched_at(riyadh.local(2025, 11, 19, 6, 5))).to be_empty
    ensure
      Rails.configuration.x.learners_enabled = true
    end

    it "skips enrollments with reminders off, completed, or an unconfirmed learner" do
      riyadh_enrollment.update!(reminders_enabled: false)
      cohort = riyadh_enrollment.cohort
      create(:enrollment, cohort: cohort, learner: create(:learner, **confirmed), completed_at: Time.current)
      create(:enrollment, cohort: cohort, learner: create(:learner, confirmed_at: nil))

      expect(dispatched_at(riyadh.local(2025, 11, 19, 6, 5))).to be_empty
    end

    it "skips enrollments already sent today but not those sent yesterday" do
      ReminderDelivery.create!(enrollment: riyadh_enrollment, local_date: Date.new(2025, 11, 19))
      ReminderDelivery.create!(enrollment: riyadh_enrollment, local_date: Date.new(2025, 11, 18))

      expect(dispatched_at(riyadh.local(2025, 11, 19, 6, 5))).to be_empty
      expect(dispatched_at(riyadh.local(2025, 11, 20, 6, 5))).to eq([ [ riyadh_enrollment.id, "2025-11-20" ] ])
    end
  end

  it "does nothing when learner mail is disabled" do
    expect(dispatched_at(riyadh.local(2025, 11, 19, 6, 5))).to be_empty
  end
end
