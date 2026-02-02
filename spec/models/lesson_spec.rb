require 'rails_helper'

RSpec.describe Lesson, type: :model do
  let(:series) { create(:series) }
  let(:lesson) { create(:lesson, series: series) }

  describe 'associations' do
    it { should belong_to(:series) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders lessons by published_at descending' do
        lesson1 = create(:lesson, published_at: 2.days.ago)
        lesson2 = create(:lesson, published_at: 1.day.ago)

        recent_lessons = Lesson.recent
        expect(recent_lessons.first).to eq(lesson2)
        expect(recent_lessons.second).to eq(lesson1)
      end
    end

    describe '.by_series' do
      it 'filters lessons by series_id when present' do
        series1 = create(:series)
        series2 = create(:series)
        lesson1 = create(:lesson, series: series1)
        lesson2 = create(:lesson, series: series2)

        series1_lessons = Lesson.by_series(series1.id)
        expect(series1_lessons).to include(lesson1)
        expect(series1_lessons).not_to include(lesson2)
      end
    end

    describe '.with_audio' do
      it 'returns lessons with audio attached' do
        lesson_with_audio = create(:lesson)
        lesson_without_audio = create(:lesson)
        lesson_without_audio.audio.purge

        lessons_with_audio = Lesson.with_audio
        expect(lessons_with_audio).to include(lesson_with_audio)
        expect(lessons_with_audio).not_to include(lesson_without_audio)
      end
    end

    describe '.without_audio' do
      it 'returns lessons without audio attached' do
        lesson_with_audio = create(:lesson)
        lesson_without_audio = create(:lesson)
        lesson_without_audio.audio.purge

        lessons_without_audio = Lesson.without_audio
        expect(lessons_without_audio).to include(lesson_without_audio)
        expect(lessons_without_audio).not_to include(lesson_with_audio)
      end
    end

    describe '.ordered_by_lesson_number' do
      it 'orders lessons by position with nulls last' do
        create(:lesson, position: 3)
        create(:lesson, position: 1)
        create(:lesson, position: nil)

        ordered_lessons = Lesson.ordered_by_lesson_number
        positions = ordered_lessons.map(&:position)
        expect(positions.compact).to eq([ 1, 3 ])
        expect(positions.last).to be_nil
      end
    end
  end

  describe 'methods' do
    describe '#full_title' do
      it 'combines series title and lesson title' do
        series = create(:series, title: 'الفقه الإسلامي')
        lesson = create(:lesson, series: series, title: 'الدرس الأول')

        expect(lesson.full_title).to eq('الفقه الإسلامي الدرس الأول')
      end
    end

    describe '#audio_url' do
      context 'when audio is attached' do
        it 'returns the audio URL' do
          expect(lesson.audio_url).to be_present
          expect(lesson.audio_url).to include('/rails/active_storage/blobs/')
        end
      end

      context 'when audio is not attached' do
        it 'returns nil' do
          lesson_without_audio = create(:lesson)
          lesson_without_audio.audio.purge
          expect(lesson_without_audio.audio_url).to be_nil
        end
      end
    end

    describe '#audio_file_size' do
      context 'when audio is attached' do
        it 'returns the file size' do
          expect(lesson.audio_file_size).to be_a(Integer)
          expect(lesson.audio_file_size).to be > 0
        end
      end

      context 'when audio is not attached' do
        it 'returns nil' do
          lesson_without_audio = create(:lesson)
          lesson_without_audio.audio.purge
          expect(lesson_without_audio.audio_file_size).to be_nil
        end
      end
    end

    describe '#podcast_title' do
      it 'includes position, series title, and lesson title' do
        series = create(:series, title: 'الفقه')
        lesson = create(:lesson, series: series, title: 'الطهارة', position: 1)

        expected_title = '1 - الفقه - الطهارة'
        expect(lesson.podcast_title).to eq(expected_title)
      end
    end

    describe '#series_title' do
      it 'returns the series title' do
        series = create(:series, title: 'التفسير')
        lesson = create(:lesson, series: series)

        expect(lesson.series_title).to eq('التفسير')
      end
    end

    describe '#extract_lesson_number' do
      it 'extracts number from title' do
        lesson = build(:lesson, title: 'الدرس 25 في الفقه')
        expect(lesson.extract_lesson_number).to eq(25)
      end

      it 'returns infinity when no number found' do
        lesson = build(:lesson, title: 'مقدمة في الفقه')
        expect(lesson.extract_lesson_number).to eq(Float::INFINITY)
      end
    end

    describe '#summary' do
      it 'returns the description' do
        lesson = create(:lesson, description: 'وصف الدرس')
        expect(lesson.summary).to eq('وصف الدرس')
      end
    end

    describe '#generate_optimize_audio_bucket_key' do
      it 'generates a structured bucket key' do
        series = create(:series, title: 'الفقه الإسلامي')
        scholar = create(:scholar, first_name: 'محمد', last_name: 'العثيمين')
        series.update(scholar: scholar)
        lesson = create(:lesson, series: series, title: 'الطهارة', position: 1)

        bucket_key = lesson.generate_optimize_audio_bucket_key



        expect(bucket_key).to eq("all-audios/#{scholar.full_name}/series/#{series.title}/#{lesson.position}.mp3")
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain, host: "test-domain-#{SecureRandom.hex(4)}.com") }
    let!(:test_lesson) { create(:lesson) }

    before do
      # Clear any existing domain assignments
      test_lesson.domain_assignments.destroy_all
      test_lesson.reload
    end

    it 'assigns lesson to domain' do
      expect {
        test_lesson.assign_to(domain)
      }.to change { test_lesson.domain_assignments.count }.by(1)
      expect(test_lesson.domains).to include(domain)
    end

    it 'checks if lesson is assigned to domain' do
      test_lesson.assign_to(domain)
      expect(test_lesson.assigned_to?(domain)).to be true
    end

    it 'unassigns lesson from domain' do
      test_lesson.assign_to(domain)
      expect {
        test_lesson.unassign_from(domain)
      }.to change { test_lesson.domain_assignments.count }.by(-1)
    end

    it 'returns assigned domains' do
      test_lesson.assign_to(domain)
      expect(test_lesson.assigned_domains).to include(domain)
    end
  end

  describe 'media handling' do
    describe '#media_type' do
      context 'when video is attached' do
        let(:lesson) { create(:lesson) }

        before do
          lesson.video.attach(
            io: StringIO.new("video content"),
            filename: "video.mp4",
            content_type: "video/mp4"
          )
        end

        it 'returns video type' do
          expect(lesson.media_type).to eq(I18n.t("common.video"))
        end
      end

      context 'when only audio is attached' do
        let(:lesson) { create(:lesson) }

        it 'returns audio type' do
          expect(lesson.media_type).to eq(I18n.t("common.audio"))
        end
      end
    end
  end

  describe 'audio migration' do
    let(:scholar) { create(:scholar, full_name: 'الشيخ محمد') }
    let(:series) { create(:series, title: 'سلسلة الفقه', scholar: scholar) }
    let(:lesson) { create(:lesson, title: 'الدرس الأول', series: series, position: 1) }

    describe '#generate_final_audio_bucket_key' do
      it 'generates correct bucket key with all fields' do
        expected_key = 'all-audios/الشيخ محمد/series/سلسلة الفقه/1.mp3'
        expect(lesson.generate_final_audio_bucket_key).to eq(expected_key)
      end

      it 'raises error for nil position' do
        lesson.position = nil
        expect {
          lesson.generate_final_audio_bucket_key
        }.to raise_error(ArgumentError, /must have a position/)
      end
    end

    describe '#migrate_to_final_audio' do
      let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'files', 'test_audio.mp3'), 'audio/mpeg') }

      context 'when optimized_audio is attached' do
        before do
          lesson.optimized_audio.attach(audio_file)
        end

        it 'migrates optimized_audio to final_audio' do
          expect(lesson.migrate_to_final_audio).to be true
          expect(lesson.final_audio).to be_attached
        end

        it 'uses correct filename' do
          lesson.migrate_to_final_audio
          expect(lesson.final_audio.filename.to_s).to eq('1.mp3')
        end

        it 'preserves audio content' do
          original_byte_size = lesson.optimized_audio.byte_size
          lesson.migrate_to_final_audio
          expect(lesson.final_audio.byte_size).to eq(original_byte_size)
        end
      end

      context 'when final_audio already exists' do
        before do
          lesson.optimized_audio.attach(audio_file)
          lesson.final_audio.attach(audio_file)
        end

        it 'skips migration and returns true' do
          expect(lesson.migrate_to_final_audio).to be true
          expect(lesson.final_audio).to be_attached
        end
      end

      context 'when optimized_audio is not attached' do
        it 'returns false' do
          expect(lesson.migrate_to_final_audio).to be false
        end
      end

      context 'when position is nil' do
        before do
          lesson.optimized_audio.attach(audio_file)
          lesson.position = nil
        end

        it 'returns false and logs error' do
          expect(Rails.logger).to receive(:error).with(/must have a position/)
          expect(lesson.migrate_to_final_audio).to be false
        end
      end
    end
  end
end
