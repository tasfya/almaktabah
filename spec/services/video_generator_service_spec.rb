# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VideoGeneratorService, type: :service do
  let(:title) { "شرح كتاب الصيام من عمدة الأحكام" }
  let(:english_title) { "Introduction to Islamic Studies" }
  let(:description) { "الدرس الأول - مقدمة في الفقه الإسلامي" }
  let(:english_description) { "First lesson - Introduction to Islamic jurisprudence" }
  let(:temp_dir)        { Rails.root.join('tmp', 'test_video_generation') }
  let(:audio_file_path) { temp_dir.join('test_audio.mp3') }
  let(:logo_file_path)  { temp_dir.join('logo.png') }

  let(:mock_audio_file) { double('audio_file') }
  let(:mock_logo_file)  { double('logo_file') }

  subject(:service) do
    described_class.new(
      title: title,
      description: description,
      audio_file: mock_audio_file,
      logo_file: mock_logo_file
    )
  end

  before do
    FileUtils.mkdir_p(temp_dir)
    FileUtils.touch(audio_file_path)
    FileUtils.touch(logo_file_path)
  end

  after do
    service.cleanup! if service.temp_dir
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe '#initialize' do
    it 'sets attributes correctly' do
      expect(service.title).to eq(title)
      expect(service.description).to eq(description)
      expect(service.audio_file).to eq(mock_audio_file)
      expect(service.logo_file).to eq(mock_logo_file)
      expect(service.temp_dir).to be_nil
    end

    it 'allows nil description' do
      s = described_class.new(title: title, audio_file: mock_audio_file, logo_file: mock_logo_file)
      expect(s.description).to be_nil
    end

    it 'includes ArabicHelper' do
      expect(service.class.included_modules).to include(ArabicHelper)
    end
  end

  describe '#call' do
    context 'success path' do
      before do
        allow(service).to receive(:setup_temp_directory)
        allow(service).to receive(:copy_file_to_temp).and_return('/tmp/test/audio.mp3', '/tmp/test/logo.png')
        allow(service).to receive(:create_background_image).and_return('/tmp/test/background.png')
        allow(service).to receive(:generate_video)
        allow(service).to receive(:transliterate_arabic).with(title).and_return('sharh-kitab-alsiyam')
        service.instance_variable_set(:@temp_dir, Pathname.new('/tmp/test'))
      end

      it 'returns success hash with filename' do
        result = service.call
        expect(result[:success]).to be true
        expect(result[:video_path]).to eq('/tmp/test/output.mp4')
        expect(result[:filename]).to eq('sharh-kitab-alsiyam.mp4')
      end
    end

    context 'failure path' do
      before do
        allow(service).to receive(:setup_temp_directory)
        allow(service).to receive(:copy_file_to_temp).and_raise(StandardError, 'File copy failed')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs and returns error' do
        result = service.call
        expect(result[:success]).to be false
        expect(result[:error]).to eq('File copy failed')
      end
    end
  end

  describe '#cleanup!' do
    before do
      service.instance_variable_set(:@temp_dir, temp_dir)
      FileUtils.mkdir_p(temp_dir)
      FileUtils.touch(temp_dir.join('t.txt'))
    end

    it 'removes directory' do
      expect(Dir.exist?(temp_dir)).to be true
      service.cleanup!
      expect(Dir.exist?(temp_dir)).to be false
    end

    it 'handles nil temp_dir gracefully' do
      service.instance_variable_set(:@temp_dir, nil)
      expect { service.cleanup! }.not_to raise_error
    end
  end

  describe 'private helpers' do
    describe '#add_text' do
      let(:mock_image) { double('img') }
      let(:combine_opts) { double('combine') }
      let(:font_path) { Rails.root.join('app/assets/fonts/ScheherazadeNew-Regular.ttf') }

      before do
        allow(mock_image).to receive(:combine_options).and_yield(combine_opts)
        allow(combine_opts).to receive_messages(font: nil, fill: nil, pointsize: nil,
                                               gravity: nil, size: nil, background: nil, annotate: nil)
      end

      it 'renders Arabic with pango markup' do
        # pango markup should be included in annotate text when arabic: true
        allow(service).to receive(:word_wrap).and_return('محتوى عربي')
        expect(combine_opts).to receive(:annotate).with('+0+60', /محتوى عربي/)
        service.send(:add_text_with_pango, mock_image, title, y_position: 600, font_size: 48, color: 'white')
      end

      it 'renders English without error' do
        allow(service).to receive(:word_wrap).and_return('wrapped english')
        expect(combine_opts).to receive(:annotate).with('+0+60', 'wrapped english')
        service.send(:add_text_simple, mock_image, english_title,
                     y_position: 600, font_size: 48, color: 'white')
      end
    end

    describe '#word_wrap' do
      it 'wraps English text' do
        result = service.send(:word_wrap, 'This is a long sentence to wrap', 10)
        expect(result.split("\n").all? { |l| l.length <= 10 }).to be true
      end
    end

    describe '#arabic_text?' do
      it { expect(service.send(:arabic_text?, 'مرحبا')).to be true }
      it { expect(service.send(:arabic_text?, 'Hello')).to be false }
    end
  end
end
