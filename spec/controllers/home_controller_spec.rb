require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }

  describe "GET #index" do
    let!(:published_series) { create_list(:series, 6, published: true, published_at: 1.day.ago) }
    let!(:published_lectures) { create_list(:lecture, 12, published: true, published_at: 1.day.ago) }

    before do
      published_series.each { |s| create(:domain_assignment, domain: domain, assignable: s) }
      published_lectures.each { |l| create(:domain_assignment, domain: domain, assignable: l) }
      get :index
    end

    it "returns a successful response" do
      expect(response).to be_successful
    end

    describe "series assignment" do
      it "assigns @series as the first published series" do
        expect(assigns(:series)).to be_present
        expect(assigns(:series)).to be_a(Series)
      end

      it "assigns @top_series excluding the first series with a limit of 5" do
        expect(assigns(:top_series)).to be_present
        expect(assigns(:top_series).count).to be <= 5
        expect(assigns(:top_series)).not_to include(assigns(:series))
      end
    end

    describe "lectures assignment" do
      it "assigns @top_lectures with limit of 10" do
        expect(assigns(:top_lectures)).to be_present
        expect(assigns(:top_lectures).count).to eq(10)
      end
    end

    context "when no content exists" do
      before do
        Series.destroy_all
        Lecture.destroy_all
        get :index
      end

      it "handles empty collections gracefully" do
        expect(assigns(:series)).to be_nil
        expect(assigns(:top_series)).to be_empty
        expect(assigns(:top_lectures)).to be_empty
      end
    end
  end
end
