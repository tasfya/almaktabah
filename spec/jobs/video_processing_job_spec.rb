require 'rails_helper'

RSpec.describe VideoProcessingJob, type: :job do
  subject(:job) { described_class.new }

  let(:item) { create(:benefit) }
  let(:test_video_content) { 'fake_video_content_for_testing' }

  def create_test_video_file
    test_video_path = Rails.root.join('spec', 'fixtures', 'files', 'test_video.mp4')
    FileUtils.mkdir_p(File.dirname(test_video_path))
    File.write(test_video_path, test_video_content, mode: 'wb')
    test_video_path
  end

  before do
    FileUtils.rm_rf(VideoProcessingJob::TEMP_DIR)
    FileUtils.rm_rf(VideoProcessingJob::AUDIO_STORAGE_DIR)
    FileUtils.rm_rf(VideoProcessingJob::THUMBNAIL_STORAGE_DIR)
    FileUtils.mkdir_p(Rails.root.join('spec', 'fixtures', 'files'))

    allow_any_instance_of(VideoToAudioConverter).to receive(:convert) do |converter|
      File.write(converter.instance_variable_get(:@output_path), 'fake_audio_content', mode: 'wb')
    end

    allow(FFMPEG::Movie).to receive(:new) do |path|
      movie = double('FFMPEG::Movie')
      allow(movie).to receive(:screenshot) do |output_path, options|
        File.write(output_path, 'fake_thumbnail_content', mode: 'wb')
      end
      movie
    end
  end

  after do
    # Clean up after each test
    FileUtils.rm_rf(VideoProcessingJob::TEMP_DIR)
    FileUtils.rm_rf(VideoProcessingJob::AUDIO_STORAGE_DIR)
    FileUtils.rm_rf(VideoProcessingJob::THUMBNAIL_STORAGE_DIR)

    # Clean up any attached files
    item.video.purge if item.video.attached?
    item.audio.purge if item.audio.attached?
    item.thumbnail.purge if item.thumbnail.attached?
  end

  describe '#perform' do
    context 'when item has no video' do
      before do
        item.video.purge if item.video.attached?
        item.audio.purge if item.audio.attached?
        item.thumbnail.purge if item.thumbnail.attached?
      end
      it 'returns early without processing' do
        expect(item.video.attached?).to be false

        result = job.perform(item)
        expect(result).to be_nil
        expect(item.audio.attached?).to be false
        expect(item.thumbnail.attached?).to be false
      end
    end

    context 'when item has video' do
      before do
        item.video.attach(
          io: StringIO.new(test_video_content),
          filename: 'test_video.mp4',
          content_type: 'video/mp4'
        )
      end

      context 'when both audio and thumbnail are already attached' do
        before do
          item.audio.attach(
            io: StringIO.new('dummy audio content'),
            filename: 'existing_audio.mp3',
            content_type: 'audio/mpeg'
          )
          item.thumbnail.attach(
            io: StringIO.new('dummy image content'),
            filename: 'existing_thumbnail.jpg',
            content_type: 'image/jpeg'
          )
        end

        it 'returns early without processing' do
          expect(item.audio.attached?).to be true
          expect(item.thumbnail.attached?).to be true

          result = job.perform(item)
          expect(result).to be_nil
          expect(item.audio.filename.to_s).to eq('existing_audio.mp3')
          expect(item.thumbnail.filename.to_s).to eq('existing_thumbnail.jpg')
        end
      end

      context 'when only audio needs processing' do
        before do
          item.thumbnail.attach(
            io: StringIO.new('dummy image content'),
            filename: 'existing_thumbnail.jpg',
            content_type: 'image/jpeg'
          )
          item.audio.purge if item.audio.attached?
        end

        it 'processes audio extraction only' do
          expect(item.audio.attached?).to be false
          expect(item.thumbnail.attached?).to be true

          job.perform(item)
          expect(item.audio.attached?).to be true
          expect(item.audio.content_type).to eq('audio/mpeg')
          expect(item.audio.filename.to_s).to match(/\.mp3$/)
          expect(item.thumbnail.filename.to_s).to eq('existing_thumbnail.jpg')
          expect(AudioOptimizationJob).to have_been_enqueued.with(item)
        end
      end

      context 'when only thumbnail needs processing' do
        before do
          item.audio.attach(
            io: StringIO.new('dummy audio content'),
            filename: 'existing_audio.mp3',
            content_type: 'audio/mpeg'
          )
          item.thumbnail.purge if item.thumbnail.attached?
        end

        it 'processes thumbnail generation only' do
          expect(item.audio.attached?).to be true
          expect(item.thumbnail.attached?).to be false

          job.perform(item)

          expect(item.thumbnail.attached?).to be true
          expect(item.thumbnail.content_type).to eq('image/jpeg')
          expect(item.thumbnail.filename.to_s).to match(/\.jpg$/)

          expect(item.audio.filename.to_s).to eq('existing_audio.mp3')
        end
      end

      context 'when both audio and thumbnail need processing' do
        before do
          item.audio.purge if item.audio.attached?
          item.thumbnail.purge if item.thumbnail.attached?
        end
        it 'processes both audio and thumbnail' do
          expect(item.audio.attached?).to be false
          expect(item.thumbnail.attached?).to be false

          job.perform(item)

          expect(item.audio.attached?).to be true
          expect(item.thumbnail.attached?).to be true

          expect(item.audio.content_type).to eq('audio/mpeg')
          expect(item.thumbnail.content_type).to eq('image/jpeg')

          expect(item.audio.filename.to_s).to match(/\.mp3$/)
          expect(item.thumbnail.filename.to_s).to match(/\.jpg$/)
        end
      end

      context 'when video has special characters in filename' do
        before do
          item.video.purge
          item.video.attach(
            io: StringIO.new(test_video_content),
            filename: 'test video!@#$%^&*()file.mp4',
            content_type: 'video/mp4'
          )
        end

        it 'handles special characters in filename correctly' do
          job.perform(item)

          expect(item.audio.attached?).to be true
          expect(item.thumbnail.attached?).to be true

          # Should successfully process despite special characters
          expect(item.audio.content_type).to eq('audio/mpeg')
          expect(item.thumbnail.content_type).to eq('image/jpeg')
        end
      end
    end
  end
end
