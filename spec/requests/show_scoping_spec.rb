# frozen_string_literal: true

require "rails_helper"

# Every public show page serves a record only when it is published and
# assigned to the requesting domain, the same rule the listings apply.
RSpec.describe "Show pages scope by domain and published state", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:other_domain) { create(:domain, host: "other.example.com") }
  let!(:scholar) { create(:scholar) }
  let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

  before { host! "localhost" }

  def create_record(factory, published:)
    attrs = { published: published, published_at: (1.day.ago if published) }
    case factory
    when :lesson then create(:lesson, series: series, **attrs)
    else create(factory, scholar: scholar, **attrs)
    end
  end

  def only_on(record, target_domain)
    record.domains = [ target_domain ]
    record.save!
    record
  end

  {
    article: [ ->(r) { article_path(r.scholar, r) }, -> { articles_path }, "article" ],
    book: [ ->(r) { book_path(r.scholar, r) }, -> { books_path }, "book" ],
    series: [ ->(r) { series_path(r.scholar, r) }, -> { series_index_path }, "series" ],
    news: [ ->(r) { news_path(r.scholar, r) }, -> { news_index_path }, "news" ],
    fatwa: [ ->(r) { fatwa_path(r.scholar, r) }, -> { fatwas_path }, "fatwa" ],
    lecture: [ ->(r) { lecture_path(r.scholar, r, kind: r.kind_for_url) }, -> { lectures_path }, "lecture" ],
    lesson: [ ->(r) { series_lesson_path(r.series.scholar, r.series, r) }, -> { series_index_path }, "lesson" ]
  }.each do |factory, (show_path, fallback_path, message)|
    describe "#{factory} show" do
      it "serves a published #{factory} assigned to this domain" do
        record = only_on(create_record(factory, published: true), domain)
        get instance_exec(record, &show_path)
        expect(response).to have_http_status(:ok)
      end

      it "does not serve a published #{factory} assigned only to another domain" do
        record = only_on(create_record(factory, published: true), other_domain)
        get instance_exec(record, &show_path)
        expect(response).to redirect_to(instance_exec(&fallback_path))
        expect(flash[:alert]).to eq(I18n.t("messages.#{message}_not_found"))
      end

      it "does not serve an unpublished #{factory} on this domain" do
        record = only_on(create_record(factory, published: false), domain)
        get instance_exec(record, &show_path)
        expect(response).to redirect_to(instance_exec(&fallback_path))
        expect(flash[:alert]).to eq(I18n.t("messages.#{message}_not_found"))
      end
    end
  end

  %i[lesson lecture].each do |factory|
    describe "play #{factory}" do
      it "serves a published #{factory} assigned to this domain" do
        record = only_on(create_record(factory, published: true), domain)
        get play_path(factory, record.id)
        expect(response).to have_http_status(:ok)
      end

      it "does not serve a published #{factory} assigned only to another domain" do
        record = only_on(create_record(factory, published: true), other_domain)
        get play_path(factory, record.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.#{factory}_not_found"))
      end
    end
  end
end
