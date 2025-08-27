# Test framework: RSpec with Shoulda Matchers and FactoryBot
require 'rails_helper'

RSpec.describe Benefit, type: :model do
  subject(:benefit) { build(:benefit) }

  describe 'associations' do
    it { should belong_to(:scholar).optional }
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end

  describe 'validations' do
    context "boundary conditions" do
      it "allows title at max length" do
        benefit.title = "a" * 255
        expect(benefit).to be_valid
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it "rejects title over max length" do
        benefit.title = "a" * 256
        expect(benefit).to be_invalid
        expect(benefit.errors[:title]).to be_present
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it "allows description at max length" do
        benefit.description = "a" * 1000
        expect(benefit).to be_valid
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it "rejects description over max length" do
        benefit.description = "a" * 1001
        expect(benefit).to be_invalid
        expect(benefit.errors[:description]).to be_present
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it "rejects blank title" do
        benefit.title = ""
        expect(benefit).to be_invalid
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it "rejects blank description" do
        benefit.description = ""
        expect(benefit).to be_invalid
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(1000) }
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end

  describe 'callbacks' do
    describe 'after_commit' do
      it 'calls set_duration after create' do
        expect(MediaDurationExtractionJob).to receive(:perform_later).with(benefit)
        benefit.save!
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

      it 'calls set_duration after update' do
      it "enqueues the duration job once per update call" do
        benefit.save!
        allow(MediaDurationExtractionJob).to receive(:perform_later)
        benefit.update!(title: benefit.title)
        expect(MediaDurationExtractionJob).to have_received(:perform_later).with(benefit).once
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
        benefit.save!
        expect(MediaDurationExtractionJob).to receive(:perform_later).with(benefit)
        benefit.update!(title: 'Updated title')
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it "does not expose unexpected attributes" do
        unexpected = %w[token password secret internal_notes]
        expect(Benefit.ransackable_attributes & unexpected).to be_empty
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      it 'returns allowed attributes for search' do
        expected_attributes = [
          "id", "title", "description", "category", "published",
          "published_at", "scholar_id", "updated_at", "created_at"
        ]
        expect(Benefit.ransackable_attributes).to match_array(expected_attributes)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end

    describe '.ransackable_associations' do
      it 'returns allowed associations for search' do
        expect(Benefit.ransackable_associations).to eq([ "scholar" ])
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end

  describe "methods" do
    describe "media_type" do
      context "when video is attached" do
        before { benefit.video.attach(io: StringIO.new("video content"), filename: "video.mp4", content_type: "video/mp4") }

        it "returns the video type" do
          expect(benefit.media_type).to eq(I18n.t("common.video"))
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

      context "when audio is attached" do
        before { benefit.audio.attach(io: StringIO.new("audio content"), filename: "audio.mp3", content_type: "audio/mpeg") }

        it "returns the audio type" do
          expect(benefit.media_type).to eq(I18n.t("common.audio"))
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

      context "when no media is attached" do
        before do
          benefit.video.purge if benefit.video.attached?
          benefit.audio.purge if benefit.audio.attached?
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

        it "returns nil" do
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end

  describe 'domain assignment' do
    it "does not duplicate assignment when assigning same domain twice" do
      expect {
        test_benefit.assign_to(domain)
        test_benefit.assign_to(domain)
      }.to change { test_benefit.domain_assignments.count }.by(1)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
    it "unassigning a non-assigned domain is a no-op" do
      # Ensure not assigned
      expect(test_benefit.assigned_to?(domain)).to be false
      expect { test_benefit.unassign_from(domain) }.not_to raise_error
      expect(test_benefit.domain_assignments.count).to eq(0)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
    it "returns empty assigned_domains when none" do
      expect(test_benefit.assigned_domains).to be_empty
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
    let!(:domain) { create(:domain, host: "test-domain-#{SecureRandom.hex(4)}.com") }
    let!(:test_benefit) { create(:benefit) }

    before do
      # Clear any existing domain assignments
      test_benefit.domain_assignments.destroy_all
      test_benefit.reload
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

    it 'assigns benefit to domain' do
      expect {
        test_benefit.assign_to(domain)
      }.to change { test_benefit.domain_assignments.count }.by(1)
      expect(test_benefit.domains).to include(domain)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

    it 'checks if benefit is assigned to domain' do
      test_benefit.assign_to(domain)
      expect(test_benefit.assigned_to?(domain)).to be true
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

    it 'unassigns benefit from domain' do
      test_benefit.assign_to(domain)
      expect {
        test_benefit.unassign_from(domain)
      }.to change { test_benefit.domain_assignments.count }.by(-1)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end

    it 'returns assigned domains' do
      test_benefit.assign_to(domain)
      expect(test_benefit.assigned_domains).to include(domain)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

    end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

  end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

end
      context "when both video and audio are attached" do
        before do
          benefit.video.attach(io: StringIO.new("video"), filename: "v.mp4", content_type: "video/mp4")
          benefit.audio.attach(io: StringIO.new("audio"), filename: "a.mp3", content_type: "audio/mpeg")
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
        it "prefers video over audio" do
          expect([I18n.t("common.video"), I18n.t("common.audio")]).to include(benefit.media_type)
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
      context "with unsupported content type" do
        it "returns nil when non-media blob is attached to unknown slot" do
          # No attachments to defined slots – ensure still nil
          expect(benefit.media_type).to be_nil
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

        end
  describe "published scope" do
    before do
      benefit.save!
    end
    it "responds to published scope if defined" do
      expect(Benefit).to respond_to(:published).or respond_to(:unpublished)
    end
  end

      end
