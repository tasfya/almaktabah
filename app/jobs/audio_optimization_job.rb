# frozen_string_literal: true

class AudioOptimizationJob < ApplicationJob
  queue_as :default

  def perform(item)
    return unless item.audio?
    return if item.optimized_audio.attached?

    item.audio.download do |original_io|
      optimized_io = AudioOptimizer.new(input_io: original_io).optimize
      original_file_name = "op_#{SecureRandom.hex(8)}.mp3"
      item.optimized_audio.attach(
        io:           optimized_io,
        filename:     original_file_name,
        content_type: "audio/mpeg"
      )
      item.save!
    end
  end
end
