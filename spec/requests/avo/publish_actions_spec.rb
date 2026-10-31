# frozen_string_literal: true

require "rails_helper"

# Runs each publish/unpublish action through Avo's action endpoint, the way the
# admin's bulk-action form submits it.
RSpec.describe "Avo publish actions", type: :request do
  include Devise::Test::IntegrationHelpers

  include_context "with tenant domain"

  let(:admin) { create(:user, admin: true) }
  let(:published_at) { Time.zone.parse("2024-05-01 09:30") }

  before { sign_in admin }

  def run_action(resource_name, action, records, **fields)
    post "/avo/resources/#{resource_name}/actions?action_id=#{action}",
         params: { fields: { avo_resource_ids: records.map(&:to_param).join(",") }.merge(fields) },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:ok)
  end

  {
    "lectures" => [ :lecture, Avo::Actions::PublishLecture, Avo::Actions::UnpublishLecture ],
    "lessons" => [ :lesson, Avo::Actions::PublishLesson, Avo::Actions::UnpublishLesson ],
    "series" => [ :series, Avo::Actions::PublishSeries, Avo::Actions::UnpublishSeries ],
    "books" => [ :book, Avo::Actions::PublishBook, Avo::Actions::UnpublishBook ]
  }.each do |resource_name, (factory, publish, unpublish)|
    describe resource_name do
      it "#{publish.name} publishes the selected records at the given time" do
        drafts = create_list(factory, 2, published: false)
        untouched = create(factory, published: false)

        run_action(resource_name, publish, drafts, published_at: published_at.iso8601)

        expect(drafts.map(&:reload)).to all(have_attributes(published: true, published_at: published_at))
        expect(untouched.reload.published).to be(false)
      end

      next if unpublish == Avo::Actions::UnpublishLesson

      it "#{unpublish.name} unpublishes the selected records and clears published_at" do
        live = create_list(factory, 2, published: true, published_at: 1.day.ago)
        untouched = create(factory, published: true)

        run_action(resource_name, unpublish, live)

        expect(live.map(&:reload)).to all(have_attributes(published: false, published_at: nil))
        expect(untouched.reload.published).to be(true)
      end
    end
  end

  # UnpublishLesson reads the ids from args[:fields][:records] instead of
  # args[:records], so it never finds the selected lessons (issue #617).
  it "Avo::Actions::UnpublishLesson leaves the selected lessons published" do
    live = create_list(:lesson, 2, published: true, published_at: 1.day.ago)

    run_action("lessons", Avo::Actions::UnpublishLesson, live)
    expect(flash[:success][:body]).to eq("Successfully unpublished 0 lesson(s)")

    expect(live.map(&:reload)).to all(have_attributes(published: true))
  end

  it "refuses a non-admin" do
    sign_out admin
    sign_in create(:user)
    draft = create(:lecture, published: false)

    post "/avo/resources/lectures/actions?action_id=Avo::Actions::PublishLecture",
         params: { fields: { avo_resource_ids: draft.to_param, published_at: published_at.iso8601 } }

    expect(response).to redirect_to("http://localhost/")
    expect(draft.reload.published).to be(false)
  end
end
