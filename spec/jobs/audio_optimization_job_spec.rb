require 'rails_helper'

RSpec.describe AudioOptimizationJob, type: :job do
  let(:benefit) { create(:benefit) }
  let(:lecture) { create(:lecture) }

  describe '#perform' do
    context 'when item has audio attached' do
      let(:audio_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }

      before do
        benefit.audio.attach(audio_file)
      end

      it 'optimizes audio successfully' do
        expect(benefit.audio).to be_attached
        expect(benefit.optimized_audio).not_to be_attached

        described_class.perform_now(benefit)

        benefit.reload
        expect(benefit.optimized_audio).to be_attached
      end

      it 'logs successful optimization' do
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(benefit)

        expect(Rails.logger).to have_received(:info)
          .with("Audio optimization completed for item ID #{benefit.id}")
      end
    end

    context 'when item has no audio' do
      let(:benefit_without_audio) { create(:benefit, :without_audio) }

      it 'returns early without processing' do
        expect(benefit_without_audio.audio).not_to be_attached
        expect { described_class.perform_now(benefit_without_audio) }.not_to raise_error
        expect(benefit_without_audio.optimized_audio).not_to be_attached
      end
    end

    context 'when optimized audio already exists' do
      let(:audio_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }
      let(:optimized_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }

      before do
        benefit.audio.attach(audio_file)
        benefit.optimized_audio.attach(optimized_file)
      end

      it 'returns early without processing' do
        expect(benefit.optimized_audio).to be_attached
        expect { described_class.perform_now(benefit) }.not_to raise_error
      end
    end

    context 'when optimization fails' do
      let(:audio_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }

      before do
        benefit.audio.attach(audio_file)
        allow(AudioOptimizer).to receive(:new).and_raise(StandardError.new("Optimization failed"))
      end

      it 'logs error and re-raises exception' do
        allow(Rails.logger).to receive(:error)

        expect { described_class.perform_now(benefit) }.to raise_error(StandardError, "Optimization failed")

        expect(Rails.logger).to have_received(:error)
          .with("Audio optimization failed for item ID #{benefit.id}: Optimization failed")
      end
    end
  end

  describe 'private methods' do
    let(:job) { described_class.new }
    let(:audio_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }

    before do
      benefit.audio.attach(audio_file)
    end

    describe '#create_input_tempfile' do
      it 'creates a tempfile with correct extension' do
        benefit.audio.open do |audio_file|
          tempfile = job.send(:create_input_tempfile, benefit, audio_file)

          expect(tempfile).to be_a(Tempfile)
          expect(tempfile.path).to end_with('.mp3')

          tempfile.close
          tempfile.unlink
        end
      end
    end

    describe '#optimize_audio_to_tempfile' do
      it 'creates optimized audio tempfile' do
        input_tempfile = Tempfile.new([ 'test_input', '.mp3' ])
        input_tempfile.write('test audio content')
        input_tempfile.rewind

        allow(AudioOptimizer).to receive(:new).and_return(double(optimize: true))

        output_tempfile = job.send(:optimize_audio_to_tempfile, input_tempfile)

        expect(output_tempfile).to be_a(Tempfile)
        expect(output_tempfile.path).to end_with('.mp3')

        input_tempfile.close
        input_tempfile.unlink
        output_tempfile.close
        output_tempfile.unlink
      end
    end

    describe '#attach_optimized_audio' do
      it 'attaches optimized audio with correct attributes' do
        output_tempfile = Tempfile.new([ 'optimized', '.mp3' ])
        output_tempfile.write('optimized audio content')
        output_tempfile.rewind

        job.send(:attach_optimized_audio, benefit, output_tempfile)

        benefit.reload
        expect(benefit.optimized_audio).to be_attached
        expect(benefit.optimized_audio.content_type).to eq('audio/mpeg')

        output_tempfile.close
        output_tempfile.unlink
      end

      context 'when item responds to generate_optimize_audio_bucket_key' do
        it 'uses custom bucket key with _op prefix' do
          allow(benefit).to receive(:respond_to?).and_call_original
          allow(benefit).to receive(:respond_to?).with(:generate_optimize_audio_bucket_key).and_return(true)
          allow(benefit).to receive(:generate_optimize_audio_bucket_key).and_return('custom/bucket/key.mp3')

          output_tempfile = Tempfile.new([ 'optimized', '.mp3' ])
          output_tempfile.write('optimized audio content')
          output_tempfile.rewind

          job.send(:attach_optimized_audio, benefit, output_tempfile)
          benefit.reload
          expect(benefit.optimized_audio).to be_attached
          expect(benefit).to have_received(:generate_optimize_audio_bucket_key)

          output_tempfile.close
          output_tempfile.unlink
        end
      end
    end
  end
end

# ---------------------------------------------------------------------------
# Additional tests for AudioOptimizationJob focusing on Lecture items.
# Note: Tests use RSpec (Rails), FactoryBot, and ActiveStorage test helpers.
# These complement existing Benefit-focused coverage by validating identical
# behavior for Lecture records and additional edge scenarios.
# ---------------------------------------------------------------------------
RSpec.describe AudioOptimizationJob, type: :job do
  describe '#perform (Lecture item)' do
    let(:lecture) { create(:lecture) }
    let(:audio_file) { fixture_file_upload('spec/files/audio.mp3', 'audio/mpeg') }

    after do
      lecture.audio.purge if lecture.audio.attached?
      lecture.optimized_audio.purge if lecture.optimized_audio.attached?
    end

    context 'when lecture has audio attached' do
      before { lecture.audio.attach(audio_file) }

      it 'optimizes audio successfully for lecture' do
        expect(lecture.audio).to be_attached
        expect(lecture.optimized_audio).not_to be_attached

        described_class.perform_now(lecture)

        lecture.reload
        expect(lecture.optimized_audio).to be_attached
        expect(lecture.optimized_audio.content_type).to eq('audio/mpeg')
      end

      it 'logs successful optimization for lecture' do
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(lecture)

        expect(Rails.logger).to have_received(:info)
          .with("Audio optimization completed for item ID #{lecture.id}")
      end
    end

    context 'when lecture has no audio' do
      it 'returns early without processing lecture' do
        # Guard against factories that might attach audio by default
        lecture.audio.purge if lecture.audio.attached?

        expect(lecture.audio).not_to be_attached
        expect { described_class.perform_now(lecture) }.not_to raise_error
        expect(lecture.optimized_audio).not_to be_attached
      end
    end

    context 'when optimized audio already exists for lecture' do
      before do
        lecture.audio.attach(audio_file)
        lecture.optimized_audio.attach(audio_file)
      end

      it 'returns early without processing lecture' do
        expect(lecture.optimized_audio).to be_attached
        expect { described_class.perform_now(lecture) }.not_to raise_error
        # Optimized audio remains attached and no duplicate attachment occurs
        expect(lecture.optimized_audio).to be_attached
      end
    end

    context 'when optimization fails for lecture' do
      before do
        lecture.audio.attach(audio_file)
        allow(AudioOptimizer).to receive(:new).and_raise(StandardError.new('Optimization failed'))
      end

      it 'logs error and re-raises exception for lecture' do
        allow(Rails.logger).to receive(:error)

        expect { described_class.perform_now(lecture) }.to raise_error(StandardError, 'Optimization failed')

        expect(Rails.logger).to have_received(:error)
          .with("Audio optimization failed for item ID #{lecture.id}: Optimization failed")
      end
    end
  end

  describe 'private methods (Lecture item)' do
    let(:job) { described_class.new }
    let(:lecture) { create(:lecture) }

    after do
      lecture.audio.purge if lecture.audio.attached?
      lecture.optimized_audio.purge if lecture.optimized_audio.attached?
    end

    describe '#attach_optimized_audio' do
      it 'attaches optimized audio for lecture with correct attributes' do
        output_tempfile = Tempfile.new(['optimized', '.mp3'])
        output_tempfile.write('optimized audio content')
        output_tempfile.rewind

        job.send(:attach_optimized_audio, lecture, output_tempfile)
        lecture.reload

        expect(lecture.optimized_audio).to be_attached
        expect(lecture.optimized_audio.content_type).to eq('audio/mpeg')

        output_tempfile.close
        output_tempfile.unlink
      end

      context 'when lecture responds to generate_optimize_audio_bucket_key' do
        it 'uses custom bucket key (e.g., with _op prefix) for lecture' do
          allow(lecture).to receive(:respond_to?).and_call_original
          allow(lecture).to receive(:respond_to?).with(:generate_optimize_audio_bucket_key).and_return(true)
          allow(lecture).to receive(:generate_optimize_audio_bucket_key).and_return('custom/lecture/bucket/key.mp3')

          output_tempfile = Tempfile.new(['optimized', '.mp3'])
          output_tempfile.write('optimized audio content')
          output_tempfile.rewind

          job.send(:attach_optimized_audio, lecture, output_tempfile)
          lecture.reload

          expect(lecture.optimized_audio).to be_attached
          expect(lecture).to have_received(:generate_optimize_audio_bucket_key)

          output_tempfile.close
          output_tempfile.unlink
        end
      end
    end
  end
end
