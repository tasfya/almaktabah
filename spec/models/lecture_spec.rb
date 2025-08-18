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

    describe '#generate_bucket_key' do
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
        allow(lecture).to receive(:slugify_arabic_advanced).with('محاضرة في الفقه').and_return('محاضرة-في-الفقه')
        allow(lecture).to receive(:slugify_arabic_advanced).with('محمد العثيمين').and_return('محمد-العثيمين')

        bucket_key = lecture.generate_bucket_key
        expect(bucket_key).to eq('scholars/محمد-العثيمين/lectures/conference/محاضرة-في-الفقه.mp3')
      end

      it 'uses the audio file extension' do
        lecture.audio.blob.update(filename: 'test.wav')
        allow(lecture).to receive(:slugify_arabic_advanced).and_return('test-slug')

        bucket_key = lecture.generate_bucket_key
        expect(bucket_key).to end_with('.wav')
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

    describe "#generate_bucket_key" do
      it "generates a structured bucket key" do
        scholar = create(:scholar, first_name: 'محمد', last_name: 'العثيمين')
        lecture = create(:lecture, title: 'محاضرة في الفقه', scholar: scholar)

        bucket_key = lecture.generate_bucket_key
        expect(bucket_key).to include('scholars/')
        expect(bucket_key).to include('lectures/')
        expect(bucket_key).to end_with('.mp3')
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
