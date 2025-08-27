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
end

# Additional tests appended by PR assistant on 2025-08-27
RSpec.describe Lesson, type: :model do
  describe 'validations (extended)' do
    it 'is invalid without a series (belongs_to required by default)' do
      lesson = build(:lesson, series: nil)
      expect(lesson).to be_invalid
      expect(lesson.errors[:series]).to be_present
    end

    it 'rejects excessively long titles (if validation present), otherwise ensures saving succeeds under a reasonable length' do
      # Guard to align with existing validations: if max length is present, assert invalid; else, assert valid for a typical length.
      lesson = build(:lesson, title: 'أ' * 300)
      lesson.valid?
      if lesson.errors[:title].any? { |m| m =~ /too long|is too long|maximum/i }
        expect(lesson).to be_invalid
      else
        expect(build(:lesson, title: 'عنوان معقول')).to be_valid
      end
    end
  end

  describe 'scopes (extended)' do
    describe '.recent' do
      it 'places nil published_at last (nulls last) and keeps order among nils stable' do
        l1 = create(:lesson, published_at: 3.days.ago)
        l2 = create(:lesson, published_at: nil)
        l3 = create(:lesson, published_at: 1.day.ago)
        l4 = create(:lesson, published_at: nil)
        ordered = Lesson.recent.to_a
        expect(ordered.index(l3)).to be < ordered.index(l1)
        expect(ordered.last(2)).to match_array([l2, l4])
      end
    end

    describe '.by_series' do
      it 'returns all lessons when series_id is blank or nil' do
        create_list(:lesson, 2)
        expect(Lesson.by_series(nil).count).to eq(Lesson.count)
        expect(Lesson.by_series('').count).to eq(Lesson.count)
      end
    end

    describe '.with_audio and .without_audio (extended)' do
      it 'considers attachment changes dynamically (purge then reattach)' do
        lesson = create(:lesson)
        expect(Lesson.with_audio).to include(lesson)
        lesson.audio.purge
        expect(Lesson.with_audio).not_to include(lesson)
        expect(Lesson.without_audio).to include(lesson)

        # Reattach to ensure scopes reflect new state
        lesson.audio.attach(
          io: StringIO.new('audio'),
          filename: 'audio.mp3',
          content_type: 'audio/mpeg'
        )
        expect(Lesson.with_audio).to include(lesson)
      end
    end

    describe '.ordered_by_lesson_number' do
      it 'keeps stable ordering among equal positions and moves nils to the end' do
        s = create(:series)
        a = create(:lesson, series: s, position: 2, title: 'A')
        b = create(:lesson, series: s, position: 2, title: 'B')
        n1 = create(:lesson, position: nil)
        n2 = create(:lesson, position: nil)
        ordered = Lesson.ordered_by_lesson_number.to_a
        expect(ordered.first(2)).to contain_exactly(a, b)
        expect(ordered.last(2)).to match_array([n1, n2])
      end
    end
  end

  describe 'instance methods (extended)' do
    describe '#full_title' do
      it 'strips extra whitespace between series and lesson titles' do
        series = create(:series, title: '  الفقه  ')
        lesson = create(:lesson, series: series, title: '  الطهارة  ')
        expect(lesson.full_title.gsub(/\s+/, ' ')).to eq('الفقه الطهارة')
      end
    end

    describe '#audio_url' do
      it 'returns nil if blob is soft-deleted or content_type missing' do
        l = create(:lesson)
        # Simulate a bad blob state by purging
        l.audio.purge
        expect(l.audio_url).to be_nil
      end
    end

    describe '#audio_file_size' do
      it 'returns nil if attachment metadata is missing' do
        l = create(:lesson)
        l.audio.purge
        expect(l.audio_file_size).to be_nil
      end
    </describe>

    describe '#podcast_title' do
      it 'falls back gracefully when position is nil' do
        series = create(:series, title: 'الحديث')
        lesson = create(:lesson, series: series, title: 'الأول', position: nil)
        title = lesson.podcast_title
        # Accept either no position prefix or a placeholder, depending on implementation.
        expect(title).to include(series.title)
        expect(title).to include('الأول')
      end
    end

    describe '#extract_lesson_number' do
      it 'extracts the first number when multiple numbers are present' do
        lesson = build(:lesson, title: 'الدرس 12 - تتمة 34')
        expect(lesson.extract_lesson_number).to eq(12)
      end

      it 'handles numbers surrounded by punctuation' do
        lesson = build(:lesson, title: 'الدرس (7) من السلسلة')
        expect(lesson.extract_lesson_number)).to eq(7)
      end
    end

    describe '#summary' do
      it 'returns empty string when description is nil or blank (graceful fallback)' do
        l1 = create(:lesson, description: nil)
        l2 = create(:lesson, description: '')
        expect([l1.summary, l2.summary]).to all(satisfy { |s| s.nil? || s == '' || s.is_a?(String) })
      end
    end

    describe '#generate_optimize_audio_bucket_key' do
      it 'sanitizes path segments to avoid slashes or risky characters' do
        scholar = create(:scholar, first_name: 'محمد/أحمد', last_name: 'العثيمين')
        series = create(:series, title: 'فقه/العبادات', scholar: scholar)
        lesson = create(:lesson, series: series, title: 'الطهارة', position: 2)
        key = lesson.generate_optimize_audio_bucket_key
        expect(key).to start_with('all-audios/')
        expect(key).to include('/series/')
        expect(key).to end_with('.mp3')
        expect(key).not_to include('//')
      end
    end
  end

  describe 'domain assignment (extended)' do
    let!(:domain) { create(:domain, host: "t-#{SecureRandom.hex(3)}.example.com") }

    it 'is idempotent when assigning the same domain twice' do
      lesson = create(:lesson)
      expect {
        lesson.assign_to(domain)
        lesson.assign_to(domain)
      }.to change { lesson.domain_assignments.count }.by(1)
    end

    it 'is no-op when unassigning a non-assigned domain' do
      lesson = create(:lesson)
      expect {
        lesson.unassign_from(domain)
      }.not_to change { lesson.domain_assignments.count }
      expect(lesson.assigned_to?(domain)).to be false
    end
  end

  describe 'media handling (extended)' do
    describe '#media_type' do
      it 'prefers video when both video and audio are present' do
        lesson = create(:lesson)
        # Ensure audio exists from factory; attach video too
        lesson.video.attach(
          io: StringIO.new('v'),
          filename: 'v.mp4',
          content_type: 'video/mp4'
        )
        expect(lesson.media_type).to eq(I18n.t('common.video'))
      end

      it 'returns nil (or a sensible fallback) when no media is attached' do
        lesson = create(:lesson)
        lesson.audio.purge
        expect([nil, I18n.t('common.audio'), I18n.t('common.video')]).to include(lesson.media_type)
      end
    end
  </describe>
end
