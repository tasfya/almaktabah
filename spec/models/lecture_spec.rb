require 'rails_helper'

RSpec.describe Lecture, type: :model do
  let(:lecture) { create(:lecture) }

  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'associations' do
    it { should belong_to(:scholar) }
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders lectures by published_at descending' do
        lecture1 = create(:lecture, published_at: 2.days.ago)
        lecture2 = create(:lecture, published_at: 1.day.ago)

        recent_lectures = Lecture.recent
        expect(recent_lectures.first).to eq(lecture2)
        expect(recent_lectures.second).to eq(lecture1)
      end
    end

    describe '.by_category' do
      it 'filters lectures by category when category is present' do
        lecture1 = create(:lecture, category: 'fiqh')
        lecture2 = create(:lecture, category: 'aqeedah')

        fiqh_lectures = Lecture.by_category('fiqh')
        expect(fiqh_lectures).to include(lecture1)
        expect(fiqh_lectures).not_to include(lecture2)
      end

      it 'returns all lectures when category is blank' do
        lecture1 = create(:lecture, category: 'fiqh')
        lecture2 = create(:lecture, category: 'aqeedah')

        all_lectures = Lecture.by_category('')
        expect(all_lectures).to include(lecture1, lecture2)
      end
    end

    describe '.with_audio' do
      it 'returns lectures with audio attached' do
        lecture_with_audio = create(:lecture)
        lecture_without_audio = create(:lecture)
        lecture_without_audio.audio.purge

        lectures_with_audio = Lecture.with_audio
        expect(lectures_with_audio).to include(lecture_with_audio)
        expect(lectures_with_audio).not_to include(lecture_without_audio)
      end
    end

    describe '.without_audio' do
      it 'returns lectures without audio attached' do
        lecture_with_audio = create(:lecture)
        lecture_without_audio = create(:lecture)
        lecture_without_audio.audio.purge

        lectures_without_audio = Lecture.without_audio
        expect(lectures_without_audio).to include(lecture_without_audio)
        expect(lectures_without_audio).not_to include(lecture_with_audio)
      end
    end
  end

  describe 'ransack configuration' do
    describe '.ransackable_attributes' do
      it 'returns allowed attributes for search' do
        expected_attributes = [
          "category", "created_at", "description", "duration", "id",
          "published", "published_at", "scholar_id", "title", "updated_at"
        ]
        expect(Lecture.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'returns allowed associations for search' do
        expect(Lecture.ransackable_associations).to eq([ "scholar" ])
      end
    end
  end

  describe 'methods' do
    describe '#podcast_title' do
      it 'returns the title' do
        lecture = create(:lecture, title: 'محاضرة في الفقه')
        expect(lecture.podcast_title).to eq('محاضرة في الفقه')
      end
    end

    describe '#audio_file_size' do
      context 'when audio is attached' do
        it 'returns the file size' do
          expect(lecture.audio_file_size).to be_a(Integer)
          expect(lecture.audio_file_size).to be > 0
        end
      end

      context 'when audio is not attached' do
        let(:lecture_without_audio) { create(:lecture) }

        before { lecture_without_audio.audio.purge }

        it 'returns nil' do
          expect(lecture_without_audio.audio_file_size).to be_nil
        end
      end
    end

    describe '#summary' do
      it 'returns the description' do
        lecture = create(:lecture, description: 'وصف المحاضرة')
        expect(lecture.summary).to eq('وصف المحاضرة')
      end
    end

    describe '#audio_url' do
      context 'when audio is attached' do
        it 'returns the audio URL' do
          expect(lecture.audio_url).to be_present
          expect(lecture.audio_url).to include('/rails/active_storage/blobs/')
        end
      end

      context 'when audio is not attached' do
        let(:lecture_without_audio) { create(:lecture) }

        before { lecture_without_audio.audio.purge }

        it 'returns nil' do
          expect(lecture_without_audio.audio_url).to be_nil
        end
      end
    end

    describe '#generate_optimize_audio_bucket_key' do
      let(:scholar) { create(:scholar, first_name: 'محمد', last_name: 'العثيمين') }
      let(:lecture) { create(:lecture, title: 'محاضرة في الفقه', scholar: scholar) }

      before do
        lecture.audio.attach(
          io: StringIO.new("audio content"),
          filename: "test.mp3",
          content_type: "audio/mpeg"
        )
      end

      it 'generates a structured bucket key' do
        lecture = create(:lecture, title: 'الطهارة')
        bucket_key = lecture.generate_optimize_audio_bucket_key
        expect(bucket_key).to eq("all-audios/#{lecture.scholar.name}/lectures/#{lecture.kind}/#{lecture.title}.mp3")
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain, host: "test-domain-#{SecureRandom.hex(4)}.com") }
    let!(:test_lecture) { create(:lecture) }

    before do
      # Clear any existing domain assignments
      test_lecture.domain_assignments.destroy_all
      test_lecture.reload
    end

    it 'assigns lecture to domain' do
      expect {
        test_lecture.assign_to(domain)
      }.to change { test_lecture.domain_assignments.count }.by(1)
      expect(test_lecture.domains).to include(domain)
    end

    it 'checks if lecture is assigned to domain' do
      test_lecture.assign_to(domain)
      expect(test_lecture.assigned_to?(domain)).to be true
    end

    it 'unassigns lecture from domain' do
      test_lecture.assign_to(domain)
      expect {
        test_lecture.unassign_from(domain)
      }.to change { test_lecture.domain_assignments.count }.by(-1)
    end

    it 'returns assigned domains' do
      test_lecture.assign_to(domain)
      expect(test_lecture.assigned_domains).to include(domain)
    end
  end

  describe "methods" do
    describe "#podcast_title" do
      it "returns the title" do
        lecture = create(:lecture, title: "محاضرة في الفقه")
        expect(lecture.podcast_title).to eq("محاضرة في الفقه")
      end
    end

    describe "#audio_file_size" do
      context "when audio is attached" do
        it "returns the file size" do
          expect(lecture.audio_file_size).to be_a(Integer)
          expect(lecture.audio_file_size).to be > 0
        end
      end

      context "when audio is not attached" do
        it "returns nil" do
          lecture.audio.purge
          expect(lecture.audio_file_size).to be_nil
        end
      end
    end

    describe "#summary" do
      it "returns the description" do
        lecture = create(:lecture, description: "وصف المحاضرة")
        expect(lecture.summary).to eq("وصف المحاضرة")
      end
    end

    describe "#audio_url" do
      context "when audio is attached" do
        it "returns the audio URL" do
          expect(lecture.audio_url).to be_present
          expect(lecture.audio_url).to include('/rails/active_storage/blobs/')
        end
      end

      context "when audio is not attached" do
        it "returns nil" do
          lecture.audio.purge
          expect(lecture.audio_url).to be_nil
        end
      end
    end
  end

  describe "scopes" do
    describe "with_audio" do
      it "returns the ones with audios" do
        lecture = create(:lecture)
        expect(Lecture.with_audio).to include(lecture)
        expect(Lecture.without_audio).to_not include(lecture)

        lecture.audio.delete
        expect(Lecture.with_audio).to_not include(lecture)
        expect(Lecture.without_audio).to include(lecture)
      end
    end
  end
end

# --- Additional comprehensive tests appended by PR tooling ---

RSpec.describe Lecture, type: :model do
  describe 'additional validations and guards' do
    it 'does not allow blank title (shoulda matcher already checks presence)' do
      l = build(:lecture, title: '')
      expect(l).not_to be_valid
      expect(l.errors[:title]).to be_present
    end

    it 'allows unicode titles and descriptions' do
      l = build(:lecture, title: 'الطهارة – مدخل', description: 'تفصيل موجز')
      expect(l).to be_valid
    end
  end

  describe 'scopes – extended' do
    describe '.recent' do
      it 'places more recent lectures first even with the same day (uses published_at time)' do
        older = create(:lecture, published_at: 2.days.ago.change(hour: 8))
        newer = create(:lecture, published_at: 2.days.ago.change(hour: 20))
        expect(Lecture.recent.take(2)).to eq([newer, older])
      end

      it 'includes records with nil published_at at the end when mixed' do
        with_time = create(:lecture, published_at: 1.day.ago)
        without_time = create(:lecture, published_at: nil)
        ordered = Lecture.recent.where(id: [with_time.id, without_time.id])
        expect(ordered.first).to eq(with_time)
        expect(ordered.last).to eq(without_time)
      end
    end

    describe '.by_category' do
      it 'returns empty relation for unknown category' do
        create(:lecture, category: 'fiqh')
        expect(Lecture.by_category('non-existent-cat')).to be_empty
      end

      it 'treats nil as blank and returns all' do
        a = create(:lecture, category: 'aqeedah')
        b = create(:lecture, category: 'seerah')
        expect(Lecture.by_category(nil)).to match_array([a, b])
      end

      it 'ignores surrounding whitespace in category input' do
        f1 = create(:lecture, category: 'fiqh')
        _a1 = create(:lecture, category: 'aqeedah')
        expect(Lecture.by_category("  fiqh  ")).to contain_exactly(f1)
      end
    end

    describe '.with_audio / .without_audio' do
      it 'excludes records after purging the attachment' do
        l = create(:lecture)
        expect(Lecture.with_audio).to include(l)
        l.audio.purge
        expect(Lecture.with_audio).not_to include(l)
        expect(Lecture.without_audio).to include(l)
      end

      it 'treats detached attachments as without_audio' do
        l = create(:lecture)
        expect(Lecture.with_audio).to include(l)
        # detach is the canonical way to remove association without deleting blob
        if l.audio.attached?
          l.audio.detach
        end
        expect(Lecture.with_audio).not_to include(l)
        expect(Lecture.without_audio).to include(l)
      end

      it 'handles multiple records across both scopes correctly' do
        with_audio_1 = create(:lecture)
        with_audio_2 = create(:lecture)
        without_audio_1 = create(:lecture).tap { |lec| lec.audio.purge }
        without_audio_2 = create(:lecture).tap { |lec| lec.audio.detach if lec.audio.attached? }

        expect(Lecture.with_audio).to include(with_audio_1, with_audio_2)
        expect(Lecture.with_audio).not_to include(without_audio_1, without_audio_2)

        expect(Lecture.without_audio).to include(without_audio_1, without_audio_2)
        expect(Lecture.without_audio).not_to include(with_audio_1, with_audio_2)
      end
    end
  end

  describe 'ransack configuration – extended' do
    it 'does not expose unsafe or non-listed attributes' do
      allowed = Lecture.ransackable_attributes
      %w[audio file blob token password secret _private].each do |disallowed|
        expect(allowed).not_to include(disallowed)
      end
    end

    it 'associations are limited to scholar only (no eager leakage)' do
      expect(Lecture.ransackable_associations).to eq(['scholar'])
    end
  end

  describe 'audio helper methods – edge cases' do
    let(:lecture_with_audio) { create(:lecture) }

    it '#audio_file_size returns an integer size that matches the blob metadata' do
      size = lecture_with_audio.audio_file_size
      expect(size).to be_a(Integer)
      expect(size).to eq(lecture_with_audio.audio.blob.byte_size)
    end

    it '#audio_url returns a stable ActiveStorage route when attached and nil otherwise' do
      expect(lecture_with_audio.audio_url).to be_present
      expect(lecture_with_audio.audio_url).to include('/rails/active_storage/blobs/')
      lecture_with_audio.audio.purge
      expect(lecture_with_audio.audio_url).to be_nil
    end
  end

  describe '#generate_optimize_audio_bucket_key – extended' do
    it 'includes scholar name, kind, and title with .mp3 extension' do
      scholar = create(:scholar, first_name: 'أحمد', last_name: 'الزيد')
      lec = create(:lecture, title: 'دروس في الحديث', scholar: scholar)
      key = lec.generate_optimize_audio_bucket_key
      expect(key).to include("all-audios/#{lec.scholar.name}/lectures/#{lec.kind}/")
      expect(key).to end_with('.mp3')
      expect(key).to include(lec.title)
    end

    it 'remains deterministic for the same record across calls' do
      lec = create(:lecture, title: 'علم الأصول')
      expect(lec.generate_optimize_audio_bucket_key).to eq(lec.generate_optimize_audio_bucket_key)
    end
  end

  describe 'domain assignment – robustness' do
    let!(:domain) { create(:domain, host: "t-#{SecureRandom.hex(3)}.example.com") }
    let!(:lecture) { create(:lecture) }

    before do
      lecture.domain_assignments.destroy_all
      lecture.reload
    end

    it 'is idempotent when assigning the same domain multiple times' do
      expect {
        lecture.assign_to(domain)
        lecture.assign_to(domain)
      }.to change { lecture.domain_assignments.count }.by(1)
      expect(lecture.domains).to contain_exactly(domain)
    end

    it 'unassigning a non-assigned domain does not raise and has no effect' do
      other_domain = create(:domain, host: "t-#{SecureRandom.hex(3)}.example.com")
      expect {
        lecture.unassign_from(other_domain)
      }.not_to change { lecture.domain_assignments.count }
      expect(lecture.assigned_to?(other_domain)).to be false
    end

    it 'assigned_domains returns empty when nothing assigned' do
      expect(lecture.assigned_domains).to be_empty
    end
  end
end
