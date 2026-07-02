# spec/helpers/podcasts_helper_spec.rb

require 'rails_helper'

RSpec.describe PodcastsHelper, type: :helper do
  describe '#get_podcast_detail' do
    let(:domain) do
      create(:domain,
        host: "test.example.com",
        podcast_title: "Test Podcast",
        podcast_author: "Test Author",
        podcast_description: "Test Description",
        podcast_artwork_url_override: "https://example.com/art.png"
      )
    end

    it 'returns podcast configuration hash' do
      result = helper.get_podcast_detail(domain: domain)

      expect(result).to be_a(Hash)
      expect(result[:website_url]).to eq("https://test.example.com/")
      expect(result[:title]).to eq("Test Podcast")
      expect(result[:author]).to eq("Test Author")
      expect(result[:description]).to eq("Test Description")
      expect(result[:artwork_url]).to eq("https://example.com/art.png")
    end

    it 'returns different details for different domains' do
      domain2 = create(:domain,
        host: "other.example.com",
        podcast_title: "Another Podcast",
        podcast_author: "Another Author",
        podcast_description: "Another Description"
      )
      result1 = helper.get_podcast_detail(domain: domain)
      result2 = helper.get_podcast_detail(domain: domain2)
      expect(result1[:title]).not_to eq(result2[:title])
    end
  end

  describe '#get_podcast_audios' do
    let(:domain) { create(:domain) }

    # Helper requires: final_audio attached, duration present, published_at present, published: true
    let!(:published_lesson1) { create(:lesson, :with_final_audio, published: true) }
    let!(:published_lesson2) { create(:lesson, :with_final_audio, published: true) }
    let!(:unpublished_lesson) { create(:lesson, :with_final_audio, published: false) }
    let!(:published_lecture1) { create(:lecture, :with_final_audio, published: true, kind: :sermon) }
    let!(:published_lecture2) { create(:lecture, :with_final_audio, published: true, kind: :sermon) }
    let!(:unpublished_lecture) { create(:lecture, :with_final_audio, published: false, kind: :sermon) }

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
      let(:other_domain) { create(:domain) }
      let!(:domain_lesson) { create(:lesson, :with_final_audio, published: true) }
      let!(:domain_lecture) { create(:lecture, :with_final_audio, published: true, kind: :sermon) }

      it 'returns only lessons and lectures for the specified domain' do
        domain_lesson.assign_to(other_domain)
        domain_lecture.assign_to(other_domain)
        result = helper.get_podcast_audios(domain_id: other_domain.id)

        expect(result).to include(domain_lesson, domain_lecture)
        expect(result).not_to include(published_lesson1, published_lecture1)
      end
    end

    context 'with both domain and scholar filters' do
      let(:other_domain) { create(:domain) }
      let(:scholar) { create(:scholar) }
      let(:series) { create(:series, scholar_id: scholar.id) }
      let!(:filtered_lesson) { create(:lesson, :with_final_audio, published: true, series: series) }
      let!(:filtered_lecture) { create(:lecture, :with_final_audio, published: true, scholar_id: scholar.id, kind: :sermon) }

      it 'returns only lessons and lectures matching both filters' do
        filtered_lesson.assign_to(other_domain)
        filtered_lecture.assign_to(other_domain)
        result = helper.get_podcast_audios(domain_id: other_domain.id)

        expect(result).to include(filtered_lesson, filtered_lecture)
        expect(result).not_to include(published_lesson1, published_lecture1)
      end
    end
  end
end
