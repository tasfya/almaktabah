# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AudioOptimizationJob, type: :job do
  include ActiveJob::TestHelper

  let(:item) { create(:benefit, :with_video) }
  let(:mock_audio_optimizer) { instance_double(AudioOptimizer) }
  let(:mock_optimized_io) { StringIO.new("optimized_audio_content") }

  describe '#perform' do
    context 'when item has audio but no optimized audio' do
      before do
        # Attach audio file to the item
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
        allow(mock_audio_optimizer).to receive(:optimize).and_return(mock_optimized_io)
      end

      it 'optimizes the audio' do
        expect(AudioOptimizer).to receive(:new).with(input_io: anything)
        expect(mock_audio_optimizer).to receive(:optimize)

        described_class.perform_now(item)
      end

      it 'attaches the optimized audio' do
        expect { described_class.perform_now(item) }.to change { item.optimized_audio.attached? }.from(false).to(true)
      end

      it 'generates a secure random filename' do
        allow(SecureRandom).to receive(:hex).with(8).and_return("abcd1234")

        described_class.perform_now(item)

        expect(item.optimized_audio.filename.to_s).to eq("op_abcd1234.mp3")
      end

      it 'sets correct content type for optimized audio' do
        described_class.perform_now(item)

        expect(item.optimized_audio.content_type).to eq("audio/mpeg")
      end

      it 'saves the item after optimization' do
        expect(item).to receive(:save!)

        described_class.perform_now(item)
      end

      it 'downloads the original audio for processing' do
        expect(item.audio).to receive(:download).and_yield(StringIO.new("audio_content"))

        described_class.perform_now(item)
      end
    end

    context 'when item does not have audio' do
      before do
        item.audio.purge if item.audio.attached?
      end

      it 'returns early without processing' do
        expect(AudioOptimizer).not_to receive(:new)
        expect(item).not_to receive(:save!)

        described_class.perform_now(item)
      end

      it 'does not attach optimized audio' do
        expect { described_class.perform_now(item) }.not_to change { item.optimized_audio.attached? }
      end
    end

    context 'when optimized audio is already attached' do
      before do
        # Attach both audio and optimized audio
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        item.optimized_audio.attach(
          io: StringIO.new("existing_optimized_content"),
          filename: "optimized.mp3",
          content_type: "audio/mpeg"
        )
      end

      it 'returns early without processing' do
        expect(AudioOptimizer).not_to receive(:new)
        expect(item).not_to receive(:save!)

        described_class.perform_now(item)
      end

      it 'does not change the existing optimized audio' do
        original_filename = item.optimized_audio.filename.to_s

        described_class.perform_now(item)

        expect(item.optimized_audio.filename.to_s).to eq(original_filename)
      end
    end

    context 'when item is not audio-enabled' do
      let(:item) { double('item', audio?: false) }

      it 'returns early without processing' do
        expect(AudioOptimizer).not_to receive(:new)

        described_class.perform_now(item)
      end
    end

    context 'when audio optimization fails' do
      before do
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
        allow(mock_audio_optimizer).to receive(:optimize).and_raise(StandardError.new("Optimization failed"))
      end

      it 'propagates the error' do
        expect { described_class.perform_now(item) }.to raise_error(StandardError, "Optimization failed")
      end

      it 'does not attach optimized audio when optimization fails' do
        expect { described_class.perform_now(item) rescue nil }.not_to change { item.optimized_audio.attached? }
      end

      it 'does not save the item when optimization fails' do
        expect(item).not_to receive(:save!)

        described_class.perform_now(item) rescue nil
      end
    end

    context 'when audio download fails' do
      before do
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(item.audio).to receive(:download).and_raise(StandardError.new("Download failed"))
      end

      it 'propagates the download error' do
        expect { described_class.perform_now(item) }.to raise_error(StandardError, "Download failed")
      end

      it 'does not create AudioOptimizer when download fails' do
        expect(AudioOptimizer).not_to receive(:new)

        described_class.perform_now(item) rescue nil
      end
    end

    context 'when attachment fails' do
      before do
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
        allow(mock_audio_optimizer).to receive(:optimize).and_return(mock_optimized_io)
        allow(item.optimized_audio).to receive(:attach).and_raise(StandardError.new("Attachment failed"))
      end

      it 'propagates the attachment error' do
        expect { described_class.perform_now(item) }.to raise_error(StandardError, "Attachment failed")
      end

      it 'does not save the item when attachment fails' do
        expect(item).not_to receive(:save!)

        described_class.perform_now(item) rescue nil
      end
    end
  end

  describe 'queue configuration' do
    it 'is configured to use the default queue' do
      expect(described_class.queue_name).to eq('default')
    end
  end

  describe 'ActiveJob integration' do
    it 'enqueues the job' do
      expect {
        described_class.perform_later(item)
      }.to enqueue_job(described_class).with(item)
    end

    it 'performs the job when enqueued' do
      # Attach audio to make the job do something
      item.audio.attach(
        io: StringIO.new("original_audio_content"),
        filename: "original.mp3",
        content_type: "audio/mpeg"
      )

      allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
      allow(mock_audio_optimizer).to receive(:optimize).and_return(mock_optimized_io)

      perform_enqueued_jobs do
        described_class.perform_later(item)
      end

      expect(item.optimized_audio).to be_attached
    end
  end

  describe 'edge cases' do
    context 'when SecureRandom fails' do
      before do
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
        allow(mock_audio_optimizer).to receive(:optimize).and_return(mock_optimized_io)
        allow(SecureRandom).to receive(:hex).and_raise(StandardError.new("Random generation failed"))
      end

      it 'propagates the random generation error' do
        expect { described_class.perform_now(item) }.to raise_error(StandardError, "Random generation failed")
      end
    end

    context 'when item save fails' do
      before do
        item.audio.attach(
          io: StringIO.new("original_audio_content"),
          filename: "original.mp3",
          content_type: "audio/mpeg"
        )

        allow(AudioOptimizer).to receive(:new).and_return(mock_audio_optimizer)
        allow(mock_audio_optimizer).to receive(:optimize).and_return(mock_optimized_io)
        allow(item).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(item))
      end

      it 'propagates the save error' do
        expect { described_class.perform_now(item) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
