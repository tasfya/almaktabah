class FinalAudioCopyJob < ApplicationJob
  queue_as :audio_copy

  def perform(record, force: false)
    return unless record.respond_to?(:optimized_audio) && record.respond_to?(:final_audio)

    FinalAudioCopier.new(record, force: force).call
  end
end
