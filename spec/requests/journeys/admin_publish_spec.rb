# frozen_string_literal: true

require "rails_helper"

# An admin publishes a draft in Avo and visitors find it: on its show page and,
# once the indexing job has run, on its listing. Unpublishing takes it back
# down from both. spec/requests/avo/publish_actions_spec.rb checks the actions
# change the record; this follows the change out to the public pages.
#
# Only "is it served" is asserted for a hidden record, not the status code:
# that is being changed from a redirect to a 404 (#613).
RSpec.describe "Journey: publish and unpublish in Avo", :typesense, type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  include_context "with tenant domain"

  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let(:admin) { create(:user, admin: true) }

  def run_action(resource_name, action, record, **fields)
    sign_in admin
    perform_enqueued_jobs do
      post "/avo/resources/#{resource_name}/actions?action_id=#{action}",
           params: { fields: { avo_resource_ids: record.to_param }.merge(fields) },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    expect(response).to have_http_status(:ok)
    sign_out admin
  end

  def expect_public(path, listing, title)
    get path
    expect(response).to have_http_status(:ok)
    expect(html.at_css("h1")&.text.to_s.strip).to eq(title)

    get listing
    expect(html.css("turbo-frame#search_content a[href]").map { |a| a["href"] }).to include(path)
  end

  def expect_hidden(path, listing, title)
    get path
    expect(response).not_to have_http_status(:ok)
    expect(response.body).not_to include(title)

    get listing
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(title)
  end

  {
    "lectures" => [ -> { create(:lecture, title: "Draft Lecture", scholar: scholar, published: false) },
                    ->(r) { lecture_path(scholar, r, kind: r.kind_for_url) }, -> { lectures_path },
                    Avo::Actions::PublishLecture, Avo::Actions::UnpublishLecture ],
    "series" => [ -> { create(:series, title: "Draft Series", scholar: scholar, published: false) },
                  ->(r) { series_path(scholar, r) }, -> { series_index_path },
                  Avo::Actions::PublishSeries, Avo::Actions::UnpublishSeries ],
    "books" => [ -> { create(:book, title: "Draft Book", scholar: scholar, published: false) },
                 ->(r) { book_path(scholar, r) }, -> { books_path },
                 Avo::Actions::PublishBook, Avo::Actions::UnpublishBook ]
  }.each do |resource_name, (build, show, listing, publish, unpublish)|
    it "#{resource_name}: a draft goes public when published and comes down when unpublished" do
      record = instance_exec(&build).tap { |r| r.update!(domains: [ domain ]) }
      path = instance_exec(record, &show)
      index = instance_exec(&listing)

      expect_hidden(path, index, record.title)

      run_action(resource_name, publish, record, published_at: 1.hour.ago.iso8601)
      expect_public(path, index, record.title)

      run_action(resource_name, unpublish, record)
      expect_hidden(path, index, record.title)
    end
  end
end
