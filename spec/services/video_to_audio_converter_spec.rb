# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VideoToAudioConverter, type: :service do
  let(:test_video_content) { File.read(Rails.root.join('spec', 'files', 'test_video.mp4')) }
  let(:input_io) { StringIO.new(test_video_content) }
  let(:bitrate) { "128k" }

  subject(:converter) { described_class.new(input_io, bitrate: bitrate) }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'sets the input_io correctly' do
        expect(converter.instance_variable_get(:@input_io)).to be_a(StringIO)
      end

      it 'sets the bitrate correctly' do
        expect(converter.instance_variable_get(:@bitrate)).to eq(bitrate)
      end
    end

    context 'with string input' do
      let(:converter) { described_class.new("test string") }

      it 'converts string to StringIO' do
        expect(converter.instance_variable_get(:@input_io)).to be_a(StringIO)
      end
    end

    context 'without bitrate parameter' do
      let(:converter) { described_class.new(input_io) }

      it 'uses default bitrate' do
        expect(converter.instance_variable_get(:@bitrate)).to eq("128k")
      end
    end

    context 'with custom bitrate' do
      let(:bitrate) { "64k" }

      it 'uses the provided bitrate' do
        expect(converter.instance_variable_get(:@bitrate)).to eq("64k")
      end
    end
  end

  describe '#convert' do
    let(:mock_stdin) { instance_double(IO) }
    let(:mock_stdout) { instance_double(IO) }
    let(:mock_wait_thread) { instance_double(Process::Waiter) }
    let(:mock_process_status) { instance_double(Process::Status, success?: true) }
    let(:output_io) { StringIO.new }

    before do
      allow(StringIO).to receive(:new).and_return(output_io)
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
          -vn
          -f mp3
          -codec:a libmp3lame
          -b:a #{bitrate}
          -ar 44100
          -ac 2
          -
        ]

        expect(Open3).to receive(:popen2).with(*expected_command)
        converter.convert
      end

      it 'copies input stream to ffmpeg stdin' do
        expect(IO).to receive(:copy_stream).with(input_io, mock_stdin)
        converter.convert
      end

      it 'copies ffmpeg stdout to output stream' do
        expect(IO).to receive(:copy_stream).with(mock_stdout, output_io)
        converter.convert
      end

      it 'closes stdin after copying input' do
        expect(mock_stdin).to receive(:close)
        converter.convert
      end

      it 'rewinds the output stream' do
        expect(output_io).to receive(:rewind)
        converter.convert
      end

      it 'returns the output IO' do
        result = converter.convert
        expect(result).to eq(output_io)
      end
    end

    context 'when ffmpeg fails' do
      let(:mock_process_status) { instance_double(Process::Status, success?: false, exitstatus: 2) }

      it 'raises an error with exit status' do
        expect { converter.convert }.to raise_error(/ffmpeg conversion failed with status 2/)
      end
    end

    context 'when an exception occurs during processing' do
      before do
        allow(Open3).to receive(:popen2).and_raise(StandardError.new("Test conversion error"))
      end

      it 'raises a VideoToAudioConverter specific error' do
        expect { converter.convert }.to raise_error(/Video to audio conversion failed: Test conversion error/)
      end
    end

    context 'with custom bitrate' do
      let(:bitrate) { "256k" }

      it 'uses the custom bitrate in ffmpeg command' do
        expected_command = %W[
          ffmpeg -loglevel error
          -i -
          -vn
          -f mp3
          -codec:a libmp3lame
          -b:a 256k
          -ar 44100
          -ac 2
          -
        ]

        expect(Open3).to receive(:popen2).with(*expected_command)
        converter.convert
      end
    end
  end

  describe '#ensure_io (private method)' do
    context 'with IO object' do
      it 'returns the IO object unchanged' do
        io_object = StringIO.new("test")
        result = converter.send(:ensure_io, io_object)
        expect(result).to eq(io_object)
      end
    end

    context 'with string' do
      it 'converts string to StringIO' do
        result = converter.send(:ensure_io, "test string")
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
        result = converter.send(:ensure_io, readable_object)
        expect(result).to eq(readable_object)
      end
    end
  end

  describe 'error handling edge cases' do
    let(:mock_stdin) { instance_double(IO) }
    let(:mock_stdout) { instance_double(IO) }
    let(:mock_wait_thread) { instance_double(Process::Waiter) }

    before do
      allow(Open3).to receive(:popen2).and_yield(mock_stdin, mock_stdout, mock_wait_thread)
      allow(mock_stdin).to receive(:close)
    end

    context 'when IO copy fails' do
      before do
        allow(IO).to receive(:copy_stream).and_raise(IOError.new("IO error"))
      end

      it 'propagates the error with converter context' do
        expect { converter.convert }.to raise_error(/Video to audio conversion failed: IO error/)
      end
    end

    context 'when thread creation fails' do
      let(:converter) { described_class.new(input_io, bitrate: bitrate) }

      before do
        allow(Thread).to receive(:new).and_raise(ThreadError.new("Thread error"))
      end

      it 'propagates the error with converter context' do
        expect { converter.convert }.to raise_error(/Video to audio conversion failed: Thread error/)
      end
    end
  end

  describe 'integration test with real video processing', :integration do
    before do
      skip "ffmpeg not available" unless system("which ffmpeg > /dev/null 2>&1")
    end

    it 'actually converts video to audio with ffmpeg' do
      skip "No real video file for integration test" unless File.exist?(Rails.root.join('spec', 'files', 'test_video.mp4'))

      real_input = File.open(Rails.root.join('spec', 'files', 'test_video.mp4'), 'rb')
      converter = described_class.new(real_input, bitrate: "64k")

      result = converter.convert

      expect(result).to be_a(StringIO)
      expect(result.size).to be > 0

      real_input.close
    end
  end
end
