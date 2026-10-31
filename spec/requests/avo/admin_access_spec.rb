# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Avo admin access", type: :request do
  include Devise::Test::IntegrationHelpers

  include_context "with tenant domain"

  let(:admin) { create(:user, admin: true) }
  let(:editor) { create(:user, admin: false) }

  [ "/avo", "/avo/resources/lectures" ].each do |path|
    describe "GET #{path}" do
      it "sends an anonymous visitor to the sign-in page" do
        get path

        expect(response).to redirect_to("http://localhost/users/sign_in")
      end

      it "turns a signed-in non-admin back to the home page" do
        sign_in editor

        get path

        expect(response).to redirect_to("http://localhost/")
        expect(flash[:alert]).to eq("You are not authorized to access this page.")
      end
    end
  end

  it "shows the admin root to an admin" do
    sign_in admin

    get "/avo"
    follow_redirect! while response.redirect?

    expect(response).to have_http_status(:ok)
    expect(request.path).to start_with("/avo")
  end

  it "lists lectures for an admin" do
    lecture = create(:lecture, title: "Unique Admin Lecture")
    sign_in admin

    get "/avo/resources/lectures"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(lecture.title)
  end
end
