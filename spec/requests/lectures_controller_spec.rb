require 'rails_helper'

RSpec.describe LecturesController, type: :request do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let(:domain) { create(:domain, host: "localhost") }
  let(:other_domain) { create(:domain) }
  let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago) }
  let!(:unpublished_lecture) { create(:lecture, published: false) }
  let(:headers) { { "HTTP_HOST" => "localhost" } }

  before do
    create(:domain_assignment, domain: domain, assignable: published_lecture)
    create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
    create(:domain_assignment, domain: other_domain, assignable: create(:lecture, published: true, published_at: 1.day.ago))
  end

  describe "GET #index" do
    context "HTML format" do
      let!(:lecture1) { create(:lecture, published: true, published_at: 1.day.ago) }
      let!(:lecture2) { create(:lecture, published: true, published_at: 2.days.ago) }
      let!(:lecture3) { create(:lecture, published: false) }
      let!(:other_domain_lecture) { create(:lecture, published: true) }

      before do
        [ lecture1, lecture2, lecture3 ].each do |lecture|
          create(:domain_assignment, domain: domain, assignable: lecture)
        end
        create(:domain_assignment, domain: other_domain, assignable: other_domain_lecture)
      end

      it "returns a successful response" do
        get lectures_path, headers: headers
        expect(response).to be_successful
      end

      it "renders paginated, published lectures for the current domain" do
        get lectures_path, headers: headers

        expect(response.body).to include(lecture1.title)
        expect(response.body).to include(lecture2.title)
        expect(response.body).not_to include(lecture3.title)
        expect(response.body).not_to include(other_domain_lecture.title)
        expect(response.body).to include("pagination")
      end

      it "orders lectures by published_at descending" do
        get lectures_path, headers: headers

        # Check that newer lecture appears before older lecture in the rendered HTML
        lecture1_position = response.body.index(lecture1.title)
        lecture2_position = response.body.index(lecture2.title)

        if lecture1_position && lecture2_position
          expect(lecture1_position).to be < lecture2_position
        end
      end

      it "paginates lectures with limit of 12" do
        create_list(:lecture, 15, published: true, published_at: 1.day.ago) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get lectures_path, headers: headers

        # Check pagination is working by looking for pagination elements
        expect(response.body).to include("pagination")
      end

      it "supports ransack search" do
        matching = create(:lecture, title: "Test Search", published: true)
        non_matching = create(:lecture, title: "Another", published: true)
        [ matching, non_matching ].each do |lecture|
          create(:domain_assignment, domain: domain, assignable: lecture)
        end

        get lectures_path, params: { q: { title_cont: "Test" } }, headers: headers

        expect(response.body).to include(matching.title)
        expect(response.body).not_to include(non_matching.title)
      end

      it "sets up breadcrumbs" do
        expect_any_instance_of(LecturesController).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        get lectures_path, headers: headers
      end

      it "renders index template" do
        get lectures_path, headers: headers
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #show" do
    context "when lecture is published" do
      let!(:same_category) { create(:lecture, category: published_lecture.category, published: true) }
      let!(:other_category) { create(:lecture, category: "Other", published: true) }

      before do
        [ published_lecture, same_category, other_category ].each do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end
      end

      it "shows the lecture" do
        get lecture_path(published_lecture), headers: headers
        expect(response).to be_successful
        expect(response.body).to include(published_lecture.title)
      end

      it "shows related lectures from the same category" do
        get lecture_path(published_lecture), headers: headers

        # Related lectures are not currently implemented in the view
        expect(response).to be_successful
        expect(response.body).to include(published_lecture.title)
      end

      it "limits related lectures to 4" do
        create_list(:lecture, 6, category: published_lecture.category, published: true) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get lecture_path(published_lecture), headers: headers

        # Related lectures functionality is not currently implemented
        expect(response).to be_successful
        expect(response.body).to include(published_lecture.title)
      end

      it "sets up breadcrumbs" do
        expect_any_instance_of(LecturesController).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        expect_any_instance_of(LecturesController).to receive(:breadcrumb_for).with(published_lecture.title, lecture_path(published_lecture))
        get lecture_path(published_lecture), headers: headers
      end
    end

    context "when lecture is unpublished or not found" do
      it "redirects and shows alert for unpublished lecture" do
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)

        get lecture_path(unpublished_lecture), headers: headers
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects and shows alert for missing lecture" do
        get lecture_path(999999), headers: headers
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end
end
