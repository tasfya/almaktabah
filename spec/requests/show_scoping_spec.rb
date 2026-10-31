# frozen_string_literal: true

require "rails_helper"

# Every public show page serves a record only when it is published and
# assigned to the requesting domain, the same rule the listings apply.
RSpec.describe "Show pages scope by domain and published state", type: :request do
  include_context "with tenant domain"

  let!(:scholar) { create(:scholar) }
  let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

  def create_record(factory, published:)
    attrs = { published: published, published_at: (1.day.ago if published) }
    case factory
    when :lesson then create(:lesson, series: series, **attrs)
    else create(factory, scholar: scholar, **attrs)
    end
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
      it_behaves_like "a domain-scoped show page",
        record: ->(published:) { create_record(factory, published: published) },
        path: show_path,
        not_found_path: fallback_path,
        not_found: "messages.#{message}_not_found"
    end
  end

  %i[lesson lecture].each do |factory|
    describe "play #{factory}" do
      it_behaves_like "a domain-scoped show page",
        record: ->(published:) { create_record(factory, published: published) },
        path: ->(r) { play_path(factory, r.id) },
        not_found_path: -> { root_path },
        not_found: "messages.#{factory}_not_found"
    end
  end
end
