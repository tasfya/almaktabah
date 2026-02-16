require 'rails_helper'

RSpec.describe VideoToAudioConverter do
  let(:input_path) { Rails.root.join('spec', 'files', 'audio.mp3') } # Using audio file as test input
  let(:output_path) { Rails.root.join('tmp', 'test_converted_audio.mp3') }
  let(:converter) { described_class.new(input_path, output_path) }

  after do
    File.delete(output_path) if File.exist?(output_path)
  end

  describe '#convert' do
    it 'creates a converted audio file' do
      result = converter.convert

      expect(File.exist?(output_path)).to be true
      expect(result).to eq(output_path.to_s)
    end

    it 'does not create audio longer than the original' do
      # Get original duration
      original_movie = FFMPEG::Movie.new(input_path.to_s)
      original_duration = original_movie.duration

      # Convert the audio
      converter.convert

      # Check converted duration
      converted_movie = FFMPEG::Movie.new(output_path.to_s)
      converted_duration = converted_movie.duration

      # The converted audio should not be significantly longer than the original
      # Allow for small floating point differences (0.1 seconds tolerance)
      expect(converted_duration).to be <= (original_duration + 0.1)
    end

    it 'creates MP3 format with correct properties' do
      converter.convert

      converted_movie = FFMPEG::Movie.new(output_path.to_s)

      # Check that basic audio properties are maintained
      expect(converted_movie.audio_channels).to be_positive
      expect(converted_movie.duration).to be_positive
      expect(converted_movie.audio_sample_rate).to eq(44100)
    end
  end

  describe 'when conversion fails' do
    let(:invalid_input_path) { '/nonexistent/file.mp4' }
    let(:converter_with_invalid_input) { described_class.new(invalid_input_path, output_path) }

    it 'handles errors gracefully' do
      expect { converter_with_invalid_input.convert }.to raise_error
    end
  end
end
