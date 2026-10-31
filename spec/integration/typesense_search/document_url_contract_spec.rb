# frozen_string_literal: true

require "rails_helper"

# Search results link to the `url` stored in each Typesense document. That
# string is computed at index time, so a route change that forgets the model's
# `typesense` block leaves every search result pointing at a dead page. Each
# example reads the stored document back, compares it with the show-page route
# helper, and follows it.
RSpec.describe "Typesense document url contract", :typesense, type: :request do
  include_context "with tenant domain"

  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  def stored_document(record)
    TypesenseSearch::Client.instance.collections[record.class.name].documents[record.id.to_s].retrieve
  end

  cases = {
    "Book" => [ -> { create(:book, title: "Url Book", scholar: scholar) }, ->(r) { book_path(r.scholar, r) } ],
    "Article" => [ -> { create(:article, title: "Url Article", scholar: scholar) }, ->(r) { article_path(r.scholar, r) } ],
    "Lecture" => [ -> { create(:lecture, title: "Url Lecture", scholar: scholar) }, ->(r) { lecture_path(r.scholar, r, kind: r.kind_for_url) } ],
    "Series" => [ -> { create(:series, title: "Url Series", scholar: scholar) }, ->(r) { series_path(r.scholar, r) } ],
    "Fatwa" => [ -> { create(:fatwa, title: "Url Fatwa", scholar: scholar) }, ->(r) { fatwa_path(r.scholar, r) } ],
    "News" => [ -> { create(:news, title: "Url News", scholar: scholar) }, ->(r) { news_path(r.scholar, r) } ]
  }

  it "covers every collection the services query" do
    expect(cases.keys).to match_array(TypesenseSearch::Collections::NAMES)
  end

  cases.each do |collection, (build, show_path)|
    describe collection do
      let(:record) { instance_exec(&build).tap { |r| r.update!(domains: [ domain ]) } }

      before { index_records(record) }

      it "stores the record's show path as the document url" do
        expect(stored_document(record)["url"]).to eq(instance_exec(record, &show_path))
      end

      it "stores a url that serves the record's show page" do
        get stored_document(record)["url"]

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(record.title))
      end
    end
  end
end
