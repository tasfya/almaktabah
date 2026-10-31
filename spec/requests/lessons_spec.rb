# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lessons", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }
  let!(:published_lesson) { create(:lesson, series: series, published: true, published_at: 1.day.ago) }
  let!(:unpublished_lesson) { create(:lesson, series: series, published: false) }

  before do
    host! "localhost"
    create(:domain_assignment, domain: domain, assignable: series)
    create(:domain_assignment, domain: domain, assignable: published_lesson)
    create(:domain_assignment, domain: domain, assignable: unpublished_lesson)
  end

  def related_lesson_links
    section = html.css("section").find { |s| s.at_css("h2")&.text&.strip == I18n.t("common.related_content") }
    return [] unless section

    lesson_prefix = "#{series_path(scholar, series)}/"
    section.css("a[href]").map { |a| a["href"] }.select { |href| href.start_with?(lesson_prefix) }.uniq
  end

  describe "GET /:scholar_id/series/:series_id/lessons/:id" do
    context "when lesson is published" do
      let!(:other_lesson) { create(:lesson, series: series, published: true, published_at: 2.days.ago) }

      before do
        create(:domain_assignment, domain: domain, assignable: other_lesson)
      end

      it "shows the lesson" do
        get series_lesson_path(scholar, series, published_lesson)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_lesson.title))
      end

      it "lists related lessons from the same series" do
        get series_lesson_path(scholar, series, published_lesson)
        expect(related_lesson_links).to include(series_lesson_path(scholar, series, other_lesson))
        expect(related_lesson_links).not_to include(series_lesson_path(scholar, series, published_lesson))
      end

      it "lists every other published lesson in the series" do
        more_lessons = create_list(:lesson, 6, series: series, published: true, published_at: 1.day.ago) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get series_lesson_path(scholar, series, published_lesson)
        expected = [ other_lesson, *more_lessons ].map { |l| series_lesson_path(scholar, series, l) }
        expect(related_lesson_links).to match_array(expected)
      end

      it "shows the series index, series and lesson breadcrumbs" do
        get series_lesson_path(scholar, series, published_lesson)
        expect(breadcrumb_trail).to eq([
          [ I18n.t("breadcrumbs.series"), series_index_path ],
          [ series.title, series_path(scholar, series) ],
          [ published_lesson.title, nil ]
        ])
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get series_lesson_path(old_slug, series.to_param, published_lesson.id)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_lesson_path(scholar, series, published_lesson))
      end
    end

    context "when lesson is unpublished or not found" do
      it "redirects for unpublished lesson" do
        get series_lesson_path(scholar.to_param, series.to_param, unpublished_lesson.id)
        expect(response).to be_not_found_page(I18n.t("messages.lesson_not_found"), back_to: series_index_path)
      end

      it "redirects for missing lesson" do
        get series_lesson_path(scholar.to_param, series.to_param, 999999)
        expect(response).to be_not_found_page(I18n.t("messages.lesson_not_found"), back_to: series_index_path)
      end
    end
  end

  describe "legacy lesson URLs" do
    let(:legacy_lessons_path) { "/#{ERB::Util.url_encode('الدروس')}" }

    it "redirects the legacy lessons index to the series index with 301" do
      get legacy_lessons_path
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_index_path)
    end

    it "redirects a legacy lesson to the nested lesson URL with 301" do
      get "#{legacy_lessons_path}/#{published_lesson.id}"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_lesson_path(scholar, series, published_lesson))
    end

    it "redirects to series index when lesson not found" do
      get "#{legacy_lessons_path}/999999"
      expect(response).to be_not_found_page(I18n.t("messages.lesson_not_found"), back_to: series_index_path)
    end
  end
end
