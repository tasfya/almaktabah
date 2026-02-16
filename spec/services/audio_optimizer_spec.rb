require 'rails_helper'

RSpec.describe AudioOptimizer do
  let(:input_path) { Rails.root.join('spec', 'files', 'audio.mp3') }
  let(:output_path) { Rails.root.join('tmp', 'test_optimized_audio.mp3') }
  let(:optimizer) { described_class.new(input_path, output_path) }

  after do
    File.delete(output_path) if File.exist?(output_path)
  end

  describe '#optimize' do
    it 'creates an optimized audio file' do
      result = optimizer.optimize

      expect(File.exist?(output_path)).to be true
      expect(result).to eq(output_path.to_s)
    end

    it 'does not create audio longer than the original' do
      # Get original duration
      original_movie = FFMPEG::Movie.new(input_path.to_s)
      original_duration = original_movie.duration

      # Optimize the audio
      optimizer.optimize

      # Check optimized duration
      optimized_movie = FFMPEG::Movie.new(output_path.to_s)
      optimized_duration = optimized_movie.duration

      # The optimized audio should not be significantly longer than the original
      # Allow for small floating point differences (0.1 seconds tolerance)
      expect(optimized_duration).to be <= (original_duration + 0.1)
    end

    it 'preserves audio quality while reducing bitrate' do
      optimizer.optimize

      optimized_movie = FFMPEG::Movie.new(output_path.to_s)

      # Check that the file size is reduced (indicating compression)
      original_size = File.size(input_path)
      optimized_size = File.size(output_path)
      expect(optimized_size).to be < original_size

      # Check that basic audio properties are maintained
      expect(optimized_movie.audio_channels).to be_positive
      expect(optimized_movie.duration).to be_positive
    end
  end

  describe 'when optimization fails' do
    let(:invalid_input_path) { '/nonexistent/file.mp3' }
    let(:optimizer_with_invalid_input) { described_class.new(invalid_input_path, output_path) }

    it 'handles errors gracefully' do
      expect { optimizer_with_invalid_input.optimize }.to raise_error
    end
  end
end
