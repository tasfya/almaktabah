require "rails_helper"
require "rake"

RSpec.describe "Final audio rake task", type: :task do
  include ActiveJob::TestHelper

  let(:audio_path) { Rails.root.join("spec", "files", "audio.mp3") }

  before :all do
    Rake.application.rake_require "tasks/final_audio"
    Rake::Task.define_task(:environment)
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
    allow(ActiveStorage::Blob).to receive(:create_and_upload!)
      .and_wrap_original { |method, **args| method.call(**args.merge(service_name: :test)) }
    Rake::Task["audio:enqueue_final_copy"].reenable
  end

  def attach_audio(record, name)
    File.open(audio_path, "rb") do |file|
      if name == :final_audio
        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: "optimized.mp3",
          content_type: "audio/mpeg",
          service_name: :test
        )
        ActiveStorage::Attachment.create!(record: record, name: name, blob: blob)
      else
        record.public_send(name).attach(
          io: file,
          filename: "optimized.mp3",
          content_type: "audio/mpeg"
        )
      end
    end
  end

  it "enqueues copy jobs and attaches when performed" do
    lesson = create(:lesson)
    attach_audio(lesson, :optimized_audio)

    expect(lesson.final_audio).not_to be_attached

    expect do
      Rake::Task["audio:enqueue_final_copy"].invoke("Lesson", "false")
    end.to have_enqueued_job(FinalAudioCopyJob).with(lesson, force: false).on_queue("audio_copy")

    perform_enqueued_jobs(only: FinalAudioCopyJob)

    lesson.reload
    expect(lesson.final_audio).to be_attached
  end

  it "skips records that already have final_audio when force is false" do
    lesson = create(:lesson)
    attach_audio(lesson, :optimized_audio)
    attach_audio(lesson, :final_audio)

    expect do
      Rake::Task["audio:enqueue_final_copy"].invoke("Lesson", "false")
    end.not_to have_enqueued_job(FinalAudioCopyJob)
  end

  it "enqueues jobs for records with final_audio when force is true" do
    lesson = create(:lesson)
    attach_audio(lesson, :optimized_audio)
    attach_audio(lesson, :final_audio)

    expect do
      Rake::Task["audio:enqueue_final_copy"].invoke("Lesson", "true")
    end.to have_enqueued_job(FinalAudioCopyJob).with(lesson, force: true).on_queue("audio_copy")
  end
end
