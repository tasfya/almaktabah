require "rails_helper"

RSpec.describe Programs::ReminderJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:cohort) { create(:cohort) }
  let!(:enrollment) { create(:enrollment, cohort: cohort, learner: create(:learner, confirmed_at: Time.current)) }
  let(:morning) { riyadh.local(2025, 11, 19, 6, 5) }

  before do
    lesson = create(:program_item, :lesson, program: cohort.program)
    create(:cohort_slot, cohort: cohort, program_item: lesson, available_on: Date.new(2025, 11, 19))
    ActionMailer::Base.deliveries.clear
  end

  def deliveries
    ActionMailer::Base.deliveries
  end

  def run(at: morning, date: "2025-11-19")
    travel_to(at) { described_class.perform_now(enrollment.id, date) }
  end

  describe "with learner mail on" do
    include_context "with learner mail on"

    it "sends once across two ticks" do
      travel_to(morning) { perform_enqueued_jobs { Programs::ReminderDispatchJob.perform_now } }
      travel_to(morning + 1.hour) { perform_enqueued_jobs { Programs::ReminderDispatchJob.perform_now } }

      expect(deliveries.size).to eq(1)
      expect(deliveries.last.to).to eq([ enrollment.learner.email ])
      expect(ReminderDelivery.sole).to have_attributes(enrollment: enrollment, local_date: Date.new(2025, 11, 19), sent_at: be_present)
    end

    it "sends nothing when the digest is empty" do
      run(at: riyadh.local(2025, 11, 20, 6, 5), date: "2025-11-20")

      expect(deliveries).to be_empty
      expect(ReminderDelivery.count).to eq(0)
    end

    it "claims before sending" do
      allow(ReminderMailer).to receive(:daily).and_wrap_original do |original, *args|
        expect(ReminderDelivery.count).to eq(1)
        original.call(*args)
      end

      run

      expect(deliveries.size).to eq(1)
    end

    it "does not send when another job holds the claim" do
      ReminderDelivery.create!(enrollment: enrollment, local_date: Date.new(2025, 11, 19))

      expect { run }.not_to raise_error
      expect(deliveries).to be_empty
    end

    it "frees the claim when the server refused the connection, so the next tick sends" do
      failing = instance_double(ActionMailer::MessageDelivery)
      allow(failing).to receive(:deliver_now).and_raise(Errno::ECONNREFUSED)
      allow(ReminderMailer).to receive(:daily).and_return(failing)

      expect { run }.to raise_error(Errno::ECONNREFUSED)
      expect(ReminderDelivery.count).to eq(0)

      allow(ReminderMailer).to receive(:daily).and_call_original
      run(at: morning + 1.hour)
      expect(deliveries.size).to eq(1)
    end

    it "keeps the claim on an ambiguous failure, so the next tick sends nothing" do
      failing = instance_double(ActionMailer::MessageDelivery)
      allow(failing).to receive(:deliver_now).and_raise(Net::ReadTimeout)
      allow(ReminderMailer).to receive(:daily).and_return(failing)

      expect { run }.to raise_error(Net::ReadTimeout)
      expect(ReminderDelivery.sole.sent_at).to be_nil

      allow(ReminderMailer).to receive(:daily).and_call_original
      run(at: morning + 1.hour)
      expect(deliveries).to be_empty
    end

    it "drops a stale job from a previous day" do
      run(at: riyadh.local(2025, 11, 20, 6, 5), date: "2025-11-19")

      expect(deliveries).to be_empty
    end

    it "does not send outside the morning window" do
      run(at: riyadh.local(2025, 11, 19, 12, 0))

      expect(deliveries).to be_empty
    end

    it "does not send to an unconfirmed learner" do
      enrollment.learner.update_columns(confirmed_at: nil)
      run

      expect(deliveries).to be_empty
    end

    it "does not send once reminders were turned off" do
      enrollment.update!(reminders_enabled: false)
      run

      expect(deliveries).to be_empty
    end

    it "is deleted with its enrollment" do
      run
      enrollment.destroy!

      expect(ReminderDelivery.count).to eq(0)
    end
  end

  it "sends nothing when learner mail is disabled" do
    run

    expect(deliveries).to be_empty
  end
end
