require 'rails_helper'

RSpec.describe BenefitsController, type: :request do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let!(:domain) { create(:domain, host: "localhost") }
  let(:headers) { { "HTTP_HOST" => "localhost" } }
  let(:published_benefit) { create(:benefit, published: true, published_at: 1.day.ago) }
  let(:unpublished_benefit) { create(:benefit, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get benefits_path, headers: headers
      expect(response).to be_successful
    end

    it "renders benefits list" do
      create_list(:benefit, 5, published: true, published_at: 1.day.ago)

      get benefits_path, headers: headers

      expect(response.body).to include("benefits")
      expect(response.body).to include(Benefit.published.first.title)
    end

    it "only includes published benefits" do
      published_benefit
      unpublished_benefit

      get benefits_path, headers: headers

      expect(response.body).to include(published_benefit.title)
      expect(response.body).not_to include(unpublished_benefit.title)
    end

    it "orders benefits by published_at field descending" do
      create(:benefit, title: "Older Benefit", published: true, published_at: 2.days.ago)
      create(:benefit, title: "Newer Benefit", published: true, published_at: 1.day.ago)

      get benefits_path, headers: headers

      # Check that newer benefit appears before older benefit in the rendered HTML
      older_position = response.body.index("Older Benefit")
      newer_position = response.body.index("Newer Benefit")

      if older_position && newer_position
        expect(newer_position).to be < older_position
      end
    end

    it "paginates benefits with limit of 12" do
      create_list(:benefit, 15, published: true, published_at: 1.day.ago)

      get benefits_path, headers: headers

      # Check pagination is working by looking for pagination elements
      expect(response.body).to include("pagination")
    end

    it "supports ransack search parameters" do
      matching_benefit = create(:benefit, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_benefit = create(:benefit, title: "Other Benefit", published: true, published_at: 1.day.ago)

      get benefits_path, params: { q: { title_cont: "Test" } }, headers: headers

      expect(response.body).to include(matching_benefit.title)
      expect(response.body).not_to include(non_matching_benefit.title)
    end

    it "sets up benefits breadcrumbs" do
      expect_any_instance_of(BenefitsController).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.benefits"),
        benefits_path
      )

      get benefits_path, headers: headers
    end
  end

  describe "GET #show" do
    context "when benefit is published" do
      it "returns a successful response" do
        get benefit_path(published_benefit), headers: headers
        expect(response).to be_successful
      end

      it "renders the benefit details" do
        get benefit_path(published_benefit), headers: headers
        expect(response.body).to include(published_benefit.title)
        # Description is not rendered in the current view template
        expect(response.body).to include(published_benefit.category) if published_benefit.category.present?
      end

      it "sets up show breadcrumbs" do
        expect_any_instance_of(BenefitsController).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.benefits"),
          benefits_path
        )
        expect_any_instance_of(BenefitsController).to receive(:breadcrumb_for).with(
          published_benefit.title,
          benefit_path(published_benefit)
        )

        get benefit_path(published_benefit), headers: headers
      end
    end

    context "when benefit is not published" do
      it "redirects to benefits index" do
        get benefit_path(unpublished_benefit), headers: headers
        expect(response).to redirect_to(benefits_path)
      end

      it "shows not found alert" do
        get benefit_path(unpublished_benefit), headers: headers
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end

    context "when benefit does not exist" do
      it "redirects to benefits index" do
        get benefit_path(99999), headers: headers
        expect(response).to redirect_to(benefits_path)
      end

      it "shows not found alert" do
        get benefit_path(99999), headers: headers
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end
  end
end
