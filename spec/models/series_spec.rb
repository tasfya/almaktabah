require 'rails_helper'

RSpec.describe Series, type: :model do
  subject(:series) { build(:series) }

  describe 'associations' do
    it { should have_many(:lessons).dependent(:destroy) }
    it { should belong_to(:scholar) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(Series.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(Series.included_modules).to include(DomainAssignable)
    end

    it 'includes Sluggable' do
      expect(Series.included_modules).to include(Sluggable)
    end
  end

  describe 'slug functionality' do
    let(:series_item) { create(:series, title: 'سلسلة دروس الفقه') }

    it 'generates a slug from the title' do
      expect(series_item.slug).to eq('سلسلة-دروس-الفقه')
    end

    it 'can be found by slug' do
      expect(Series.friendly.find(series_item.slug)).to eq(series_item)
    end

    it 'maintains slug history when title changes' do
      old_slug = series_item.slug
      series_item.update!(title: 'سلسلة دروس التفسير')

      expect(series_item.slug).to eq('سلسلة-دروس-التفسير')
      expect(Series.friendly.find(old_slug)).to eq(series_item)
    end

    it 'works with English titles' do
      english_series = create(:series, title: 'Islamic Studies Series')
      expect(english_series.slug).to eq('islamic-studies-series')
    end
  end

  describe 'scopes' do
    describe '.recent' do
      let!(:old_series) { create(:series, published_at: 2.weeks.ago) }
      let!(:new_series) { create(:series, published_at: 1.week.ago) }

      it 'orders series by published_at descending' do
        expect(Series.recent).to eq([ new_series, old_series ])
      end
    end

    describe '.by_category' do
      let!(:series1) { create(:series, category: 'Education') }
      let!(:series2) { create(:series, category: 'Religious') }

      it 'filters by category when provided' do
        expect(Series.by_category('Education')).to include(series1)
        expect(Series.by_category('Education')).not_to include(series2)
      end

      it 'returns all when category is blank' do
        expect(Series.by_category('')).to include(series1, series2)
      end
    end

    describe '.with_lessons' do
      let!(:series_with_lessons) { create(:series) }
      let!(:series_without_lessons) { create(:series) }

      before do
        create(:lesson, series: series_with_lessons)
      end

      it 'returns only series with lessons' do
        expect(Series.with_lessons).to include(series_with_lessons)
        expect(Series.with_lessons).not_to include(series_without_lessons)
      end
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "category", "created_at", "description", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
        expect(Series.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = [ "lessons", "scholar" ]
        expect(Series.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain) }
    let!(:test_series) { create(:series, :without_domain) }

    before do
      test_series.assign_to(domain)
    end

    it 'assigns series to domain' do
      expect(test_series.domains).to include(domain)
    end

    it 'checks if series is assigned to domain' do
      expect(test_series.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns series from domain' do
      test_series.unassign_from(domain)
      expect(test_series.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      expect(test_series.assigned_domains).to include(domain)
    end

    context 'propagation to lessons' do
      let!(:series_with_lessons) { create(:series, :without_domain) }
      let!(:lesson1) { create(:lesson, series: series_with_lessons) }
      let!(:lesson2) { create(:lesson, series: series_with_lessons) }

      it 'assigns domain to all lessons when series is assigned (domain object)' do
        series_with_lessons.assign_to(domain)

        expect(lesson1.reload.domains).to include(domain)
        expect(lesson2.reload.domains).to include(domain)
      end

      it 'assigns domain when passed a domain id' do
        series_with_lessons.assign_to(domain)

        expect(lesson1.reload.domains).to include(domain)
      end

      it 'does not error if some lessons already assigned' do
        lesson1.assign_to(domain)
        expect { series_with_lessons.assign_to(domain) }.not_to raise_error
        expect(lesson1.reload.domains).to include(domain)
        expect(lesson2.reload.domains).to include(domain)
      end
    end
  end
end
