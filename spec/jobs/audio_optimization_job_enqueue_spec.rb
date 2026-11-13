require "rails_helper"

RSpec.describe AudioOptimizationJob, "enqueue timing" do
  include ActiveJob::TestHelper

  it "is enqueued only once the transaction that attached the audio commits" do
    lesson = create(:lesson, :without_audio)
    enqueued_inside = nil

    ActiveRecord::Base.transaction do
      lesson.audio.attach(io: Rails.root.join("spec/files/audio.mp3").open, filename: "audio.mp3")
      enqueued_inside = enqueued_jobs.count { _1["job_class"] == "AudioOptimizationJob" }
    end

    expect(enqueued_inside).to eq(0)
    expect(enqueued_jobs.count { _1["job_class"] == "AudioOptimizationJob" }).to eq(1)
  end
end
