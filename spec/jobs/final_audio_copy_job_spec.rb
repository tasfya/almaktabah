require "rails_helper"

RSpec.describe FinalAudioCopyJob, type: :job do
  it "uses the audio_copy queue" do
    expect(described_class.queue_name).to eq("audio_copy")
  end

  it "invokes the copier for records with audio attachments" do
    lesson = create(:lesson)
    copier = instance_double(FinalAudioCopier, call: true)

    expect(FinalAudioCopier).to receive(:new).with(lesson, force: true).and_return(copier)

    described_class.perform_now(lesson, force: true)
  end

  it "skips records without the required attachments" do
    record = double("record")

    expect(FinalAudioCopier).not_to receive(:new)

    described_class.perform_now(record)
  end
end
