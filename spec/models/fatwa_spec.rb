require 'rails_helper'

RSpec.describe Fatwa, type: :model do
  subject(:fatwa) { build(:fatwa) }

  describe 'associations' do
    it { should have_rich_text(:question) }
    it { should have_rich_text(:answer) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(Fatwa.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(Fatwa.included_modules).to include(DomainAssignable)
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "category", "description", "created_at", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
        expect(Fatwa.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = [ "scholar" ]
        expect(Fatwa.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'slug functionality' do
    context 'when title is in Arabic' do
      it 'generates slug from Arabic title' do
        arabic_fatwa = create(:fatwa, title: 'ما حكم الصلاة في المسجد؟')
        expect(arabic_fatwa.slug).to eq('ما-حكم-الصلاة-في-المسجد')
      end

      it 'can be found using friendly finder' do
        arabic_fatwa = create(:fatwa, title: 'حكم قراءة القرآن للحائض')
        found_fatwa = Fatwa.friendly.find('حكم-قراءة-القرآن-للحائض')
        expect(found_fatwa).to eq(arabic_fatwa)
      end
    end

    context 'when title is in English' do
      it 'generates slug from English title' do
        english_fatwa = create(:fatwa, title: 'What is the ruling on prayer in mosque?')
        expect(english_fatwa.slug).to eq('what-is-the-ruling-on-prayer-in-mosque')
      end

      it 'can be found using friendly finder' do
        english_fatwa = create(:fatwa, title: 'Islamic Finance Principles')
        found_fatwa = Fatwa.friendly.find('islamic-finance-principles')
        expect(found_fatwa).to eq(english_fatwa)
      end
    end

    context 'slug history' do
      it 'maintains old slug when title changes' do
        fatwa = create(:fatwa, title: 'أحكام الزكاة')
        old_slug = fatwa.slug

        fatwa.update(title: 'فقه الزكاة والصدقات')
        fatwa.reload

        expect(fatwa.slug).to eq('فقه-الزكاة-والصدقات')
        expect(Fatwa.friendly.find(old_slug)).to eq(fatwa)
        expect(Fatwa.friendly.find('فقه-الزكاة-والصدقات')).to eq(fatwa)
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain) }
    let!(:test_fatwa) { create(:fatwa, :without_domain) }

    before do
      test_fatwa.assign_to(domain)
    end

    it 'assigns fatwa to domain' do
      expect(test_fatwa.domains).to include(domain)
    end

    it 'checks if fatwa is assigned to domain' do
      expect(test_fatwa.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns fatwa from domain' do
      test_fatwa.unassign_from(domain)
      expect(test_fatwa.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      expect(test_fatwa.assigned_domains).to include(domain)
    end
  end

  describe 'audio migration' do
    let(:scholar) { create(:scholar, full_name: 'الشيخ محمد') }
    let(:fatwa) { create(:fatwa, title: 'حكم الصيام', category: 'صيام', scholar: scholar) }

    describe '#generate_final_audio_bucket_key' do
      it 'generates correct bucket key with all fields' do
        expected_key = 'all-audios/الشيخ محمد/fatawas/صيام/حكم الصيام.mp3'
        expect(fatwa.generate_final_audio_bucket_key).to eq(expected_key)
      end

      it 'uses "general" for nil category' do
        fatwa.category = nil
        expected_key = 'all-audios/الشيخ محمد/fatawas/general/حكم الصيام.mp3'
        expect(fatwa.generate_final_audio_bucket_key).to eq(expected_key)
      end

      it 'uses id for nil title' do
        fatwa.title = nil
        expected_key = "all-audios/الشيخ محمد/fatawas/صيام/#{fatwa.id}.mp3"
        expect(fatwa.generate_final_audio_bucket_key).to eq(expected_key)
      end
    end

    describe '#migrate_to_final_audio' do
      let(:audio_file) { fixture_file_upload(Rails.root.join('spec', 'files', 'test_audio.mp3'), 'audio/mpeg') }

      context 'when optimized_audio is attached' do
        before do
          fatwa.optimized_audio.attach(audio_file)
        end

        it 'preserves audio content' do
          original_byte_size = fatwa.optimized_audio.byte_size
          fatwa.migrate_to_final_audio
          expect(fatwa.final_audio.byte_size).to eq(original_byte_size)
        end
      end

      context 'when optimized_audio is not attached' do
        it 'returns false' do
          expect(fatwa.migrate_to_final_audio).to be false
        end
      end
    end
  end
 end
