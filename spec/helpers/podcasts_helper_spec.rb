# spec/helpers/podcasts_helper_spec.rb

require 'rails_helper'

RSpec.describe PodcastsHelper, type: :helper do
  describe '#get_podcast_detail' do
    it 'returns podcast configuration hash' do
      result = helper.get_podcast_detail

      expect(result).to be_a(Hash)
      expect(result[:website_url]).to eq("https://mohammed-ramzan.com/")
      expect(result[:title]).to eq("محمد بن رمزان الهاجري")
      expect(result[:author]).to eq("محمد بن رمزان الهاجري")
      expect(result[:description]).to eq("دروس و محاضرات فضيلة الشيخ محمد بن رمزان الهاجري")
      expect(result[:art_work]).to eq("https://suhayimi.hachimy.com/assets/logo-4f3e7f2e.png")
    end

    it 'ignores domain_id and scholar_id parameters' do
      result1 = helper.get_podcast_detail(domain_id: 1, scholar_id: 2)
      result2 = helper.get_podcast_detail
      expect(result1).to eq(result2)
    end
  end

  describe '#get_podcast_audios' do
    let(:domain) { create(:domain) }
    let!(:published_lesson1) { create(:lesson, published: true) }
    let!(:published_lesson2) { create(:lesson, published: true) }
    let!(:unpublished_lesson) { create(:lesson, published: false) }
    let!(:published_lecture1) { create(:lecture, published: true) }
    let!(:published_lecture2) { create(:lecture, published: true) }
    let!(:unpublished_lecture) { create(:lecture, published: false) }


    context 'without filters' do
      it 'returns all published lessons and lectures' do
        published_lesson1.assign_to(domain)
        published_lesson2.assign_to(domain)
        unpublished_lesson.assign_to(domain)
        published_lecture1.assign_to(domain)
        published_lecture2.assign_to(domain)
        unpublished_lecture.assign_to(domain)
        result = helper.get_podcast_audios(domain_id: domain.id)

        expect(result).to include(published_lesson1, published_lesson2)
        expect(result).to include(published_lecture1, published_lecture2)
        expect(result).not_to include(unpublished_lesson, unpublished_lecture)
      end
    end

    context 'with domain filter' do
      let(:domain) { create(:domain) }
      let!(:domain_lesson) { create(:lesson, published: true) }
      let!(:domain_lecture) { create(:lecture, published: true) }

      it 'returns only lessons and lectures for the specified domain' do
        domain_lesson.assign_to(domain)
        domain_lecture.assign_to(domain)
        result = helper.get_podcast_audios(domain_id: domain.id)

        expect(result).to include(domain_lesson, domain_lecture)
        expect(result).not_to include(published_lesson1, published_lecture1)
      end
    end

    context 'with scholar filter' do
      let(:scholar) { create(:scholar) }
      let(:series) { create(:series, scholar: scholar) }
      let(:lesson) { create(:lesson, series: series) }
      let!(:scholar_lesson) { create(:lesson, published: true, series: series) }
      let!(:scholar_lecture) { create(:lecture, published: true, scholar: scholar) }
    end

    context 'with both domain and scholar filters' do
      let(:domain) { create(:domain) }
      let(:scholar) { create(:scholar) }
      let(:series) { create(:series, scholar_id: scholar.id) }
      let!(:filtered_lesson) { create(:lesson, published: true, series: series) }
      let!(:filtered_lecture) { create(:lecture, published: true, scholar_id: scholar.id) }

      it 'returns only lessons and lectures matching both filters' do
        filtered_lesson.assign_to(domain)
        filtered_lecture.assign_to(domain)
        result = helper.get_podcast_audios(domain_id: domain.id)

        expect(result).to include(filtered_lesson, filtered_lecture)
        expect(result).not_to include(published_lesson1, published_lecture1)
      end
    end
  end
end
