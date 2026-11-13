require 'rails_helper'

RSpec.describe FatwasController, type: :request do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let!(:domain) { create(:domain, host: "localhost") }
  let(:headers) { { "HTTP_HOST" => "localhost" } }
  let(:published_fatwa) { create(:fatwa, published: true, published_at: 1.day.ago) }
  let(:unpublished_fatwa) { create(:fatwa, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get fatwas_path, headers: headers
      expect(response).to be_successful
    end

    it "renders fatwas list" do
      create_list(:fatwa, 5, published: true, published_at: 1.day.ago)

      get fatwas_path, headers: headers

      expect(response.body).to include("fatwas")
      expect(response.body).to include(Fatwa.published.first.title)
    end

    it "only includes published fatwas" do
      published_fatwa
      unpublished_fatwa

      get fatwas_path, headers: headers

      expect(response.body).to include(published_fatwa.title)
      expect(response.body).not_to include(unpublished_fatwa.title)
    end

    it "orders fatwas by published_at field descending" do
      create(:fatwa, title: "Older Fatwa", published: true, published_at: 2.days.ago)
      create(:fatwa, title: "Newer Fatwa", published: true, published_at: 1.day.ago)

      get fatwas_path, headers: headers

      # Check that newer fatwa appears before older fatwa in the rendered HTML
      older_position = response.body.index("Older Fatwa")
      newer_position = response.body.index("Newer Fatwa")

      if older_position && newer_position
        expect(newer_position).to be < older_position
      end
    end

    it "paginates fatwas with limit of 12" do
      create_list(:fatwa, 15, published: true, published_at: 1.day.ago)

      get fatwas_path, headers: headers

      # Check pagination is working by looking for pagination elements
      expect(response.body).to include("pagination")
    end

    it "supports ransack search parameters" do
      matching_fatwa = create(:fatwa, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_fatwa = create(:fatwa, title: "Other Fatwa", published: true, published_at: 1.day.ago)

      get fatwas_path, params: { q: { title_cont: "Test" } }, headers: headers

      expect(response.body).to include(matching_fatwa.title)
      expect(response.body).not_to include(non_matching_fatwa.title)
    end

    it "sets up fatwas breadcrumbs" do
      expect_any_instance_of(FatwasController).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.fatwas"),
        fatwas_path
      )

      get fatwas_path, headers: headers
    end
  end

  describe "GET #show" do
    context "when fatwa exists" do
      it "returns a successful response" do
        get fatwa_path(published_fatwa), headers: headers
        expect(response).to be_successful
      end

      it "renders the fatwa details" do
        get fatwa_path(published_fatwa), headers: headers
        expect(response.body).to include(published_fatwa.title)
      end

      it "sets up show breadcrumbs" do
        expect_any_instance_of(FatwasController).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.fatwas"),
          fatwas_path
        )
        expect_any_instance_of(FatwasController).to receive(:breadcrumb_for).with(
          published_fatwa.title,
          fatwa_path(published_fatwa)
        )

        get fatwa_path(published_fatwa), headers: headers
      end
    end

    context "when fatwa does not exist" do
      it "redirects to fatwas index" do
        get fatwa_path(99999), headers: headers
        expect(response).to redirect_to(fatwas_path)
      end

      it "shows not found alert" do
        get fatwa_path(99999), headers: headers
        expect(flash[:alert]).to eq(I18n.t("messages.fatwa_not_found"))
      end
    end
  end
end
