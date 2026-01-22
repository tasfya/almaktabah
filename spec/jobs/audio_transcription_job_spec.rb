require 'rails_helper'

RSpec.describe AudioTranscriptionJob, type: :job do
  describe "#perform_later" do
    it "queues the job on the low queue" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        AudioTranscriptionJob.perform_later(create(:lecture))
      }.to have_enqueued_job.on_queue(:low)
    end
  end
end
