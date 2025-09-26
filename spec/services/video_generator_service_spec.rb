require 'rails_helper'

RSpec.describe VideoGeneratorService, type: :service do
  let(:title) { "شرح كتاب الصيام من عمتاب الصيام من عمدة الأحكام" }
  let(:description) { " 1-الدرس الأول" }
  let(:audio_file) { double("audio_file") }
  let(:logo_file) { double("logo_file") }
  let(:temp_dir) { Pathname.new("/tmp/test_video_gen") }
  let(:service) do
    described_class.new(
      title: title,
      description: description,
      audio_file: audio_file,
      logo_file: logo_file
    )
  end

  before do
    service.instance_variable_set(:@temp_dir, temp_dir)
    allow(service).to receive(:transliterate_arabic).and_return("sharh-kitab")
    allow(service).to receive(:setup_temp_directory)
    allow(service).to receive(:copy_file_to_temp).and_return("fake_path")
    allow(service).to receive(:create_background_image).and_return("background.png")
    allow(service).to receive(:generate_video)
    allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:size).and_return(1000)
    allow(FileUtils).to receive(:rm_rf)
  end

  describe '#call' do
    context 'when generation is successful' do
      let(:result) { service.call }

      it 'returns a success status' do
        expect(result[:success]).to be true
      end

      it 'returns the correct filename' do
        expect(result[:filename]).to eq("sharh-kitab.mp4")
      end

      it 'returns the video path' do
        expect(result[:video_path]).to eq(temp_dir.join("output.mp4").to_s)
      end

      it 'generates a non-empty video file' do
        expect(File.exist?(result[:video_path])).to be true
        expect(File.size(result[:video_path])).to be > 0
      end

      it 'creates a temporary directory for processing' do
        expect(Dir.exist?(service.temp_dir)).to be true
      end
    end

    context 'when generation fails' do
      let(:invalid_audio_file) { 'non_existent_file.mp3' }
      let(:service_with_invalid_file) do
        described_class.new(
          title: title,
          description: description,
          audio_file: invalid_audio_file,
          logo_file: logo_file
        )
      end
      let(:result) { service_with_invalid_file.call }

      before do
        service_with_invalid_file.instance_variable_set(:@temp_dir, temp_dir)
        allow(service_with_invalid_file).to receive(:transliterate_arabic).and_return("sharh-kitab")
        allow(service_with_invalid_file).to receive(:setup_temp_directory)
        allow(service_with_invalid_file).to receive(:copy_file_to_temp).and_raise(ArgumentError.new("Unsupported file type: String"))
        allow(service_with_invalid_file).to receive(:create_background_image).and_return("background.png")
        allow(service_with_invalid_file).to receive(:generate_video)
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(FileUtils).to receive(:rm_rf)
      end

      it 'returns a failure status' do
        expect(result[:success]).to be false
      end

      it 'returns an error message' do
        expect(result[:error]).to eq("Unsupported file type: String")
      end
    end
  end

  describe '#cleanup!' do
    before do
      allow(Dir).to receive(:exist?).with(temp_dir).and_return(true, false)
    end

    it 'removes the temporary directory and all its contents' do
      service.call
      expect(Dir.exist?(service.temp_dir)).to be true

      service.cleanup!
      expect(Dir.exist?(service.temp_dir)).to be false
    end
  end
end
