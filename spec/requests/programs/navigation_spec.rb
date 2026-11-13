require "rails_helper"

RSpec.describe "Programs in the site navigation", type: :request do
  include Devise::Test::IntegrationHelpers

  include_context "with tenant domain"

  let(:dashboard_href) { learner_dashboard_path }

  def chrome_hrefs
    page = Nokogiri::HTML(response.body)
    {
      desktop: page.css("header nav a").map { |a| a["href"] },
      mobile: page.css("#mobile-menu a").map { |a| a["href"] },
      footer: page.css("footer a").map { |a| a["href"] }
    }
  end

  def header_html
    Nokogiri::HTML(response.body).at_css("header").to_html
  end

  before { allow(DomainContentTypesService).to receive(:for_domain).and_return([ { type: "series" } ]) }

  context "when the site has a published program" do
    before { create(:program, published: true).update!(domains: [ domain ]) }

    it "links programs and the learner's area in the desktop nav, the mobile menu and the footer" do
      get root_path

      chrome_hrefs.each_value { |hrefs| expect(hrefs).to include(programs_path, dashboard_href) }
    end

    it "renders the same header for a guest and a signed-in learner, since pages are publicly cached" do
      get root_path
      guest_header = header_html

      sign_in create(:learner, full_name: "اسم لا يظهر في الرأس")
      get root_path

      expect(header_html).to eq(guest_header)
      expect(response.body).not_to include("اسم لا يظهر في الرأس")
    end
  end

  it "shows no program links on a site without a published program" do
    create(:program, published: false).update!(domains: [ domain ])
    create(:program, published: true).update!(domains: [ other_domain ])

    get root_path

    chrome_hrefs.each_value { |hrefs| expect(hrefs).not_to include(programs_path, dashboard_href) }
  end

  describe "with the launch switch off" do
    around do |example|
      Rails.configuration.x.learners_enabled = false
      example.run
    ensure
      Rails.configuration.x.learners_enabled = true
    end

    it "shows no program links" do
      create(:program, published: true).update!(domains: [ domain ])

      get root_path

      chrome_hrefs.each_value { |hrefs| expect(hrefs).not_to include(programs_path, dashboard_href) }
    end
  end

  it "sends a guest from the learner area to sign-in with an informational notice, not an error" do
    get learner_dashboard_path
    follow_redirect!

    page = Nokogiri::HTML(response.body)
    expect(page.at_css(".alert-info").text).to include(I18n.t("devise.failure.learner.unauthenticated"))
    expect(page.at_css(".alert-error")).to be_nil
  end
end
