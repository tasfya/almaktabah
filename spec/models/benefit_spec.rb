require 'rails_helper'

RSpec.describe Benefit, type: :model do
  subject(:benefit) { build(:benefit) }

  describe 'associations' do
    it { should belong_to(:scholar).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }
  end

  describe 'callbacks' do
    describe 'after_commit' do
      it 'calls set_duration after create' do
        expect(MediaDurationExtractionJob).to receive(:perform_later).with(benefit)
        benefit.save!
      end

      it 'calls set_duration after update' do
        benefit.save!
        expect(MediaDurationExtractionJob).to receive(:perform_later).with(benefit)
        benefit.update!(title: 'Updated title')
      end
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'returns allowed attributes for search' do
        expected_attributes = [
          "id", "title", "description", "category", "published",
          "published_at", "scholar_id", "updated_at", "created_at"
        ]
        expect(Benefit.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'returns allowed associations for search' do
        expect(Benefit.ransackable_associations).to eq([ "scholar" ])
      end
    end
  end

  describe "methods" do
    describe "media_type" do
      context "when video is attached" do
        before { benefit.video.attach(io: StringIO.new("video content"), filename: "video.mp4", content_type: "video/mp4") }

        it "returns the video type" do
          expect(benefit.media_type).to eq(I18n.t("common.video"))
        end
      end

      context "when audio is attached" do
        before { benefit.audio.attach(io: StringIO.new("audio content"), filename: "audio.mp3", content_type: "audio/mpeg") }

        it "returns the audio type" do
          expect(benefit.media_type).to eq(I18n.t("common.audio"))
        end
      end

      context "when no media is attached" do
        before do
          benefit.video.purge if benefit.video.attached?
          benefit.audio.purge if benefit.audio.attached?
        end

        it "returns nil" do
          expect(benefit.media_type).to be_nil
        end
      end
    end

    describe '#generate_bucket_key' do
      let(:scholar) { create(:scholar, first_name: 'محمد', last_name: 'العثيمين') }
      let(:benefit) { create(:benefit, :with_scholar, title: 'فائدة في الصلاة', scholar: scholar) }

      before do
        benefit.audio.attach(
          io: StringIO.new("audio content"),
          filename: "test.mp3",
          content_type: "audio/mpeg"
        )
      end

      it 'generates a structured bucket key' do
        allow(benefit).to receive(:slugify_arabic_advanced).with('فائدة في الصلاة').and_return('فائدة-في-الصلاة')
        allow(benefit).to receive(:slugify_arabic_advanced).with('محمد العثيمين').and_return('محمد-العثيمين')

        bucket_key = benefit.generate_bucket_key
        expect(bucket_key).to eq('scholars/محمد-العثيمين/benefits/فائدة-في-الصلاة.mp3')
      end

      it 'uses the audio file extension' do
        benefit.audio.blob.update(filename: 'test.wav')
        allow(benefit).to receive(:slugify_arabic_advanced).and_return('test-slug')

        bucket_key = benefit.generate_bucket_key
        expect(bucket_key).to end_with('.wav')
      end

      context 'when benefit has no scholar' do
        let(:benefit_without_scholar) { create(:benefit, title: 'فائدة في الصلاة') }

        before do
          benefit_without_scholar.scholar = nil
          benefit_without_scholar.audio.attach(
            io: StringIO.new("audio content"),
            filename: "test.mp3",
            content_type: "audio/mpeg"
          )
        end

        it 'uses unknown-scholar as default' do
          allow(benefit_without_scholar).to receive(:slugify_arabic_advanced).with('فائدة في الصلاة').and_return('فائدة-في-الصلاة')

          bucket_key = benefit_without_scholar.generate_bucket_key
          expect(bucket_key).to include('scholars/unknown-scholar/benefits/')
        end
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain, host: "test-domain-#{SecureRandom.hex(4)}.com") }
    let!(:test_benefit) { create(:benefit) }

    before do
      # Clear any existing domain assignments
      test_benefit.domain_assignments.destroy_all
      test_benefit.reload
    end

    it 'assigns benefit to domain' do
      expect {
        test_benefit.assign_to(domain)
      }.to change { test_benefit.domain_assignments.count }.by(1)
      expect(test_benefit.domains).to include(domain)
    end

    it 'checks if benefit is assigned to domain' do
      test_benefit.assign_to(domain)
      expect(test_benefit.assigned_to?(domain)).to be true
    end

    it 'unassigns benefit from domain' do
      test_benefit.assign_to(domain)
      expect {
        test_benefit.unassign_from(domain)
      }.to change { test_benefit.domain_assignments.count }.by(-1)
    end

    it 'returns assigned domains' do
      test_benefit.assign_to(domain)
      expect(test_benefit.assigned_domains).to include(domain)
    end
  end
end
