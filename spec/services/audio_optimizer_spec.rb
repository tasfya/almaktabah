# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AudioOptimizer, type: :service do
  let(:test_audio_content) { File.read(Rails.root.join('spec', 'files', 'audio.mp3')) }
  let(:input_io) { StringIO.new(test_audio_content) }
  let(:output_io) { StringIO.new }
  let(:bitrate) { "64k" }

  subject(:optimizer) { described_class.new(input_io: input_io, output_io: output_io, bitrate: bitrate) }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'sets the input_io correctly' do
        expect(optimizer.instance_variable_get(:@input_io)).to be_a(StringIO)
      end

      it 'sets the output_io correctly' do
        expect(optimizer.instance_variable_get(:@output_io)).to eq(output_io)
      end

      it 'sets the bitrate correctly' do
        expect(optimizer.instance_variable_get(:@bitrate)).to eq(bitrate)
      end
    end

    context 'with string input' do
      let(:optimizer) { described_class.new(input_io: "test string") }

      it 'converts string to StringIO' do
        expect(optimizer.instance_variable_get(:@input_io)).to be_a(StringIO)
      end
    end

    context 'without output_io' do
      let(:optimizer) { described_class.new(input_io: input_io) }

      it 'creates a default StringIO for output' do
        expect(optimizer.instance_variable_get(:@output_io)).to be_a(StringIO)
      end
    end

    context 'without bitrate' do
      let(:optimizer) { described_class.new(input_io: input_io) }

      it 'uses default bitrate' do
        expect(optimizer.instance_variable_get(:@bitrate)).to eq(AudioOptimizer::DEFAULT_BITRATE)
      end
    end
  end

  describe '#optimize' do
    let(:mock_stdin) { instance_double(IO) }
    let(:mock_stdout) { instance_double(IO) }
    let(:mock_wait_thread) { instance_double(Process::Waiter) }
    let(:mock_process_status) { instance_double(Process::Status, success?: true) }

    before do
      allow(Open3).to receive(:popen2).and_yield(mock_stdin, mock_stdout, mock_wait_thread)
      allow(mock_wait_thread).to receive(:value).and_return(mock_process_status)
      allow(mock_stdin).to receive(:close)
      allow(IO).to receive(:copy_stream)
      allow(output_io).to receive(:rewind)
    end

    context 'when ffmpeg succeeds' do
      it 'executes the correct ffmpeg command' do
        expected_command = %W[
          ffmpeg -loglevel error
          -i -
          -f mp3
          -codec:a libmp3lame
          -b:a #{bitrate}
          -fflags +fastseek+genpts
          -avoid_negative_ts make_zero
          -
        ]

        expect(Open3).to receive(:popen2).with(*expected_command)
        optimizer.optimize
      end

      it 'copies input stream to ffmpeg stdin' do
        expect(IO).to receive(:copy_stream).with(input_io, mock_stdin)
        optimizer.optimize
      end

      it 'copies ffmpeg stdout to output stream' do
        expect(IO).to receive(:copy_stream).with(mock_stdout, output_io)
        optimizer.optimize
      end

      it 'rewinds the output stream' do
        expect(output_io).to receive(:rewind)
        optimizer.optimize
      end

      it 'returns the output IO' do
        result = optimizer.optimize
        expect(result).to eq(output_io)
      end
    end

    context 'when ffmpeg fails' do
      let(:mock_process_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

      it 'raises an error with exit status' do
        expect { optimizer.optimize }.to raise_error(/ffmpeg failed \(exit 1\)/)
      end
    end

    context 'when an exception occurs during processing' do
      before do
        allow(Open3).to receive(:popen2).and_raise(StandardError.new("Test error"))
      end

      it 'raises an AudioOptimizer specific error' do
        expect { optimizer.optimize }.to raise_error(/Audio optimization failed: Test error/)
      end
    end

    context 'with custom bitrate' do
      let(:bitrate) { "128k" }

      it 'uses the custom bitrate in ffmpeg command' do
        expected_command = %W[
          ffmpeg -loglevel error
          -i -
          -f mp3
          -codec:a libmp3lame
          -b:a 128k
          -fflags +fastseek+genpts
          -avoid_negative_ts make_zero
          -
        ]

        expect(Open3).to receive(:popen2).with(*expected_command)
        optimizer.optimize
      end
    end
  end

  describe '#ensure_io (private method)' do
    context 'with IO object' do
      it 'returns the IO object unchanged' do
        io_object = StringIO.new("test")
        result = optimizer.send(:ensure_io, io_object)
        expect(result).to eq(io_object)
      end
    end

    context 'with string' do
      it 'converts string to StringIO' do
        result = optimizer.send(:ensure_io, "test string")
        expect(result).to be_a(StringIO)
        expect(result.read).to eq("test string")
      end
    end

    context 'with object that responds to read' do
      let(:readable_object) do
        double('readable').tap do |obj|
          allow(obj).to receive(:respond_to?).with(:read).and_return(true)
        end
      end

      it 'returns the object unchanged' do
        result = optimizer.send(:ensure_io, readable_object)
        expect(result).to eq(readable_object)
      end
    end
  end

  describe 'integration test with real audio processing', :integration do
    # Skip this test if ffmpeg is not available
    before do
      skip "ffmpeg not available" unless system("which ffmpeg > /dev/null 2>&1")
    end

    it 'actually processes audio with ffmpeg' do
      # Use a minimal valid MP3 content or skip if no real audio file
      skip "No real audio file for integration test" unless File.exist?(Rails.root.join('spec', 'files', 'audio.mp3'))

      real_input = File.open(Rails.root.join('spec', 'files', 'audio.mp3'), 'rb')
      real_output = StringIO.new

      optimizer = described_class.new(input_io: real_input, output_io: real_output, bitrate: "32k")
      result = optimizer.optimize

      expect(result).to eq(real_output)
      expect(real_output.size).to be > 0

      real_input.close
    end
  end
end
