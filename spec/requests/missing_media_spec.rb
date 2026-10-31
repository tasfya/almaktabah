# frozen_string_literal: true

require "rails_helper"

# Media can be absent in two ways: never attached, or attached with the object
# gone from the bucket. Neither may break the page: it still answers 200, and
# every media element carries the client-side fallback that takes over when the
# browser fails to load it (spec/system/missing_media_spec.rb).
RSpec.describe "Pages with missing media", type: :request do
  include_context "with tenant domain"

  let(:scholar) { create(:scholar) }

  def delete_object(attachment)
    File.delete(ActiveStorage::Blob.service.path_for(attachment.blob.key))
  end

  describe "book download" do
    let(:book) { create(:book, scholar: scholar).tap { |b| b.update!(domains: [ domain ]) } }

    it "offers the download when the PDF object exists" do
      get book_path(scholar, book)

      expect(html.at_css("article a[target='_blank'][href*='/rails/active_storage/']")).to be_present
    end

    it "replaces the download with the unavailable notice when its object is gone" do
      delete_object(book.file)

      get book_path(scholar, book)

      expect(response).to have_http_status(:ok)
      expect(html.at_css("article a[href*='/rails/active_storage/']")).to be_nil
      expect(html.at_css("article").text).to include(I18n.t("common.media_unavailable"))
    end

    it "keeps the download when the storage service cannot be reached" do
      allow(ActiveStorage::Blob.service).to receive(:exist?).and_raise(Errno::ECONNREFUSED)

      get book_path(scholar, book)

      expect(response).to have_http_status(:ok)
      expect(html.at_css("article a[href*='/rails/active_storage/']")).to be_present
    end
  end

  describe "news show" do
    let(:news) { create(:news, scholar: scholar, published_at: 1.day.ago).tap { |n| n.update!(domains: [ domain ]) } }

    it "renders the image with a placeholder fallback when its object is gone" do
      delete_object(news.thumbnail)

      get news_path(scholar, news)

      expect(response).to have_http_status(:ok)
      img = html.at_css("article img")
      expect(img["data-controller"]).to eq("image-fallback")
      expect(img["data-image-fallback-src-value"]).to include("media-placeholder")
    end

    it "renders no image when none was attached" do
      news.thumbnail.purge

      get news_path(scholar, news)

      expect(response).to have_http_status(:ok)
      expect(html.at_css("article img")).to be_nil
    end
  end

  describe "domain logo" do
    it "falls back to the default logo in the header and footer when its object is gone" do
      domain.logo.attach(io: Rails.root.join("spec/files/logo.png").open, filename: "logo.png", content_type: "image/png")
      delete_object(domain.logo)
      news = create(:news, scholar: scholar, published_at: 1.day.ago).tap { |n| n.update!(domains: [ domain ]) }

      get news_path(scholar, news)

      expect(response).to have_http_status(:ok)
      [ "header img", "footer img" ].each do |selector|
        img = html.at_css(selector)
        expect(img["data-controller"]).to eq("image-fallback")
        expect(img["data-image-fallback-src-value"]).to match(%r{/assets/logo})
      end
    end
  end

  describe "video on show pages" do
    shared_examples "a video with a fallback" do
      it "renders the player with the unavailable notice when its object is gone" do
        delete_object(record.video)

        get path

        expect(response).to have_http_status(:ok)
        wrapper = html.at_css("[data-controller='media-fallback']")
        expect(wrapper.at_css("video[data-media-fallback-target='media'] source")).to be_present
        notice = wrapper.at_css("[data-media-fallback-target='notice']")
        expect(notice["hidden"]).not_to be_nil
        expect(notice.text).to eq(I18n.t("common.media_unavailable"))
      end

      it "renders no player when no video was attached" do
        record.video.purge

        get path

        expect(response).to have_http_status(:ok)
        expect(html.at_css("article video")).to be_nil
      end
    end

    context "with a lecture" do
      let(:record) { create(:lecture, scholar: scholar).tap { |l| l.update!(domains: [ domain ]) } }
      let(:path) { lecture_path(scholar, record, kind: record.kind_for_url) }

      it_behaves_like "a video with a fallback"
    end

    context "with a lesson" do
      let(:series) { create(:series, scholar: scholar).tap { |s| s.update!(domains: [ domain ]) } }
      let(:record) { create(:lesson, :with_video, series: series).tap { |l| l.update!(domains: [ domain ]) } }
      let(:path) { series_lesson_path(scholar, series, record) }

      it_behaves_like "a video with a fallback"
    end

    context "with a fatwa" do
      let(:record) do
        create(:fatwa, scholar: scholar, published_at: 1.day.ago).tap do |f|
          f.video.attach(io: Rails.root.join("spec/files/test_video.mp4").open, filename: "v.mp4", content_type: "video/mp4")
          f.update!(domains: [ domain ])
        end
      end
      let(:path) { fatwa_path(scholar, record) }

      it_behaves_like "a video with a fallback"
    end
  end

  describe "audio player" do
    it "renders the player with the unavailable notice when its object is gone" do
      lecture = create(:lecture, scholar: scholar, video: nil).tap { |l| l.update!(domains: [ domain ]) }
      delete_object(lecture.audio)

      get play_path("lecture", lecture.id), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      fragment = Nokogiri::HTML(response.body)
      expect(fragment.at_css("[data-controller='media-fallback'] audio[data-media-fallback-target='media']")).to be_present
      expect(fragment.at_css("[data-media-fallback-target='notice']")["hidden"]).not_to be_nil
    end
  end
end
