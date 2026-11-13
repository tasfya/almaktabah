# frozen_string_literal: true

require "rails_helper"

# Every site shares the header and footer. Each must carry only its own
# domain's logo, name and social links, never bin Ramzan's.
RSpec.describe "Site branding", type: :request do
  let(:binramzan_youtube) { "https://www.youtube.com/@bin-ramzan" }
  let(:binramzan_x) { "https://x.com/Moh1Rz2H3?ref" }
  let(:scholar) { create(:scholar) }

  def visit_news_on(domain)
    news = create(:news, scholar: scholar, published_at: 1.day.ago).tap { |n| n.update!(domains: [ domain ]) }
    host! domain.host
    get news_path(scholar, news)
    expect(response).to have_http_status(:ok)
  end

  def attach_logo(domain)
    domain.logo.attach(io: Rails.root.join("spec/files/logo.png").open, filename: "logo.png", content_type: "image/png")
  end

  def hrefs = html.css("footer a").map { _1["href"] }

  context "with a site that has no logo or social links" do
    let(:domain) { create(:domain, host: "3ilm.example.test", title: "العلم") }

    before { visit_news_on(domain) }

    it "shows the site's name as text in the header and footer, and no logo" do
      expect(html.css("header [data-site-name]").map(&:text)).to eq([ "العلم" ])
      expect(html.css("footer [data-site-name]").map(&:text)).to eq([ "العلم" ])
      expect(html.css("header img, footer img")).to be_empty
    end

    it "never falls back to the bundled bin Ramzan logo" do
      expect(response.body).not_to include("/assets/logo")
    end

    it "links to no YouTube or X account, and drops the contact column" do
      expect(hrefs).not_to include(binramzan_youtube, binramzan_x)
      expect(hrefs.grep(/youtube\.com|x\.com/)).to be_empty
      expect(html.at_css("footer").text).not_to include(I18n.t("footer.contact_title"))
    end
  end

  context "with a site that has a logo" do
    let(:domain) { create(:domain, host: "scholar.example.test", title: "الشيخ فلان") }

    before do
      attach_logo(domain)
      visit_news_on(domain)
    end

    it "shows its logo, with its name ready but hidden in case the logo fails to load" do
      %w[header footer].each do |region|
        brand = html.at_css("#{region} [data-controller='site-logo']")
        expect(brand.at_css("img[data-site-logo-target='image']")["src"]).to include("logo.png")
        expect(brand.at_css("img")["src"]).not_to include("/assets/")
        name = brand.at_css("[data-site-logo-target='name']")
        expect(name.text).to eq("الشيخ فلان")
        expect(name).to have_attribute("hidden")
      end
    end
  end

  context "with a site that has social links" do
    let(:domain) do
      create(:domain, host: "binramzan.example.test", youtube_url: binramzan_youtube, x_url: binramzan_x)
    end

    before { visit_news_on(domain) }

    it "links to its own YouTube and X accounts" do
      expect(hrefs).to include(binramzan_youtube, binramzan_x)
      expect(html.at_css("footer").text).to include(I18n.t("footer.contact_title"))
    end
  end

  context "with a site that has only a YouTube channel" do
    let(:domain) { create(:domain, host: "yt.example.test", youtube_url: "https://www.youtube.com/@someone") }

    before { visit_news_on(domain) }

    it "links to that channel and to no X account" do
      expect(hrefs).to include("https://www.youtube.com/@someone")
      expect(hrefs.grep(/x\.com/)).to be_empty
    end
  end
end
