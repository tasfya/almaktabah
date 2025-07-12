require 'rails_helper'
require 'fileutils'
require 'ostruct'

# This spec will perform real file operations and generate a video.
# Make sure you have FFmpeg and ImageMagick installed on your system.
RSpec.describe VideoGeneratorService, type: :service do
  # --- Test Setup ---
  # Create a temporary directory to store test assets
  let!(:assets_dir) { Rails.root.join("spec", "files") }
  let!(:audio_file_path) { assets_dir.join("audio.mp3") }
  let!(:logo_file_path) { assets_dir.join("logo.png") }

  # --- Shared Service Instance ---
  # Define the service instance with common parameters
  let(:title) { "شرح كتاب الصيام من عمتاب الصيام من عمدة الأحكام" }
  let(:description) { " 1-الدرس الأول" }
  let(:audio_file) { File.open(audio_file_path) }
  let(:logo_file) { File.open(logo_file_path) }

  # The service instance that will be tested
  let(:service) do
    described_class.new(
      title: title,
      description: description,
      audio_file: audio_file,
      logo_file: logo_file
    )
  end

  # --- Test Cases ---

  # Test suite for the main #call method
  xdescribe '#call', :real_files do
    context 'when generation is successful' do
      let(:result) { service.call }
      let(:video_path) { result[:video_path] }


      # Clean up the generated files after the test
      after do
        service.cleanup!
      end

      it 'returns a success status' do
        expect(result[:success]).to be true
      end

      it 'returns the correct filename' do
        expect(result[:filename]).to include('.mp4')
      end

      it 'generates a non-empty video file' do
        expect(File.exist?(video_path)).to be true
        expect(File.size(video_path)).to be > 0
      end

      it 'creates a temporary directory for processing' do
        service.call
        expect(Dir.exist?(service.temp_dir)).to be true
      end
    end

    context 'when generation fails' do
      # Use an invalid audio file to trigger a failure
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

      after do
        service_with_invalid_file.cleanup!
      end

      it 'returns a failure status' do
        expect(result[:success]).to be false
      end

      it 'returns an error message' do
        expect(result[:error]).to include("Unsupported file type")
      end
    end
  end

  # Test suite for the #cleanup! method
  xdescribe '#cleanup!' do
    it 'removes the temporary directory and all its contents' do
      # First, call the service to create the temp directory
      result = service.call
      expect(Dir.exist?(service.temp_dir)).to be true

      # Now, run cleanup
      service.cleanup!
      expect(Dir.exist?(service.temp_dir)).to be false
    end
  end

  # --- Teardown ---
  # Remove the assets directory after all tests are done
  after(:all) do
    assets_dir = Rails.root.join("tmp", "spec_assets")
    FileUtils.rm_rf(assets_dir) if Dir.exist?(assets_dir)
  end
end
