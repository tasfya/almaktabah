# frozen_string_literal: true

# Fixed records shared by the URL contract specs. Every value that ends up in a
# public URL (slug source, id) is literal, and time is frozen, so a golden file
# or a literal path changes only when the app's output changes.
#
# The expected URL segments below are hard-coded on purpose: they must not be
# built with route helpers or I18n, otherwise renaming a segment in
# config/locales/ar.yml changes the app and the expectation together.
module UrlContract
  FROZEN_AT = Time.utc(2026, 1, 15, 9, 0, 0)

  BOOKS = "%D8%A7%D9%84%D9%83%D8%AA%D8%A8"                         # الكتب
  ARTICLES = "%D8%A7%D9%84%D9%85%D9%82%D8%A7%D9%84%D8%A7%D8%AA"    # المقالات
  SERIES = "%D8%A7%D9%84%D8%B3%D9%84%D8%A7%D8%B3%D9%84"            # السلاسل
  LESSONS = "%D8%A7%D9%84%D8%AF%D8%B1%D9%88%D8%B3"                 # الدروس
  LECTURES = "%D8%A7%D9%84%D9%85%D8%AD%D8%A7%D8%B6%D8%B1%D8%A7%D8%AA" # المحاضرات
  NEWS = "%D8%A7%D9%84%D8%A3%D8%AE%D8%A8%D8%A7%D8%B1"              # الأخبار
  FATWAS = "%D8%A7%D9%84%D9%81%D8%AA%D8%A7%D9%88%D9%89"            # الفتاوى

  KIND_SERMON = "%D8%AE%D8%B7%D8%A8%D8%A9"                         # خطبة
  KIND_CONFERENCE = "%D9%85%D8%AD%D8%A7%D8%B6%D8%B1%D8%A9"         # محاضرة
  KIND_BENEFIT = "%D9%81%D8%A7%D8%A6%D8%AF%D8%A9"                  # فائدة

  SCHOLAR_SLUG = "%D9%85%D8%AD%D9%85%D8%AF-%D8%A7%D9%84%D9%87%D8%A7%D8%AC%D8%B1%D9%8A" # محمد-الهاجري
  BOOK_SLUG = "%D9%83%D8%AA%D8%A7%D8%A8-%D8%A7%D9%84%D8%AA%D9%88%D8%AD%D9%8A%D8%AF"     # كتاب-التوحيد
  ARTICLE_SLUG = "%D9%85%D9%82%D8%A7%D9%84%D8%A9-%D9%81%D9%8A-%D8%A7%D9%84%D8%B9%D9%82%D9%8A%D8%AF%D8%A9" # مقالة-في-العقيدة
  SERIES_SLUG = "%D8%B4%D8%B1%D8%AD-%D8%A7%D9%84%D8%A3%D8%B5%D9%88%D9%84-%D8%A7%D9%84%D8%AB%D9%84%D8%A7%D8%AB%D8%A9" # شرح-الأصول-الثلاثة
  NEWS_SLUG = "%D8%AE%D8%A8%D8%B1-%D8%A7%D9%84%D8%AF%D8%B1%D8%B3-%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF" # خبر-الدرس-الجديد
  FATWA_SLUG = "%D8%AD%D9%83%D9%85-%D8%B5%D9%84%D8%A7%D8%A9-%D8%A7%D9%84%D8%AC%D9%85%D8%A7%D8%B9%D8%A9" # حكم-صلاة-الجماعة
  SERMON_SLUG = "%D8%AE%D8%B7%D8%A8%D8%A9-%D8%A7%D9%84%D8%AC%D9%85%D8%B9%D8%A9"          # خطبة-الجمعة
  CONFERENCE_SLUG = "%D9%85%D8%AD%D8%A7%D8%B6%D8%B1%D8%A9-%D8%A7%D9%84%D8%B9%D9%84%D9%85" # محاضرة-العلم
  BENEFIT_SLUG = "%D9%81%D8%A7%D8%A6%D8%AF%D8%A9-%D9%81%D9%8A-%D8%A7%D9%84%D9%86%D9%8A%D8%A9" # فائدة-في-النية
  OLD_SLUG = "%D8%A7%D9%84%D8%A7%D8%B3%D9%85-%D8%A7%D9%84%D9%82%D8%AF%D9%8A%D9%85"       # الاسم-القديم
  OLD_TITLE = "الاسم القديم"

  BOOK_ID = 901
  ARTICLE_ID = 902
  SERIES_ID = 903
  LESSON_ID = 904
  NEWS_ID = 905
  FATWA_ID = 906
  SERMON_ID = 911
  CONFERENCE_ID = 912
  BENEFIT_ID = 913

  SHOW_PATHS = {
    book: "/#{SCHOLAR_SLUG}/#{BOOKS}/#{BOOK_SLUG}",
    article: "/#{SCHOLAR_SLUG}/#{ARTICLES}/#{ARTICLE_SLUG}",
    series: "/#{SCHOLAR_SLUG}/#{SERIES}/#{SERIES_SLUG}",
    lesson: "/#{SCHOLAR_SLUG}/#{SERIES}/#{SERIES_SLUG}/#{LESSONS}/#{LESSON_ID}",
    news: "/#{SCHOLAR_SLUG}/#{NEWS}/#{NEWS_SLUG}",
    fatwa: "/#{SCHOLAR_SLUG}/#{FATWAS}/#{FATWA_SLUG}",
    sermon: "/#{SCHOLAR_SLUG}/#{LECTURES}/#{KIND_SERMON}/#{SERMON_SLUG}",
    conference: "/#{SCHOLAR_SLUG}/#{LECTURES}/#{KIND_CONFERENCE}/#{CONFERENCE_SLUG}",
    benefit: "/#{SCHOLAR_SLUG}/#{LECTURES}/#{KIND_BENEFIT}/#{BENEFIT_SLUG}"
  }.freeze
end

RSpec.shared_context "with fixed url contract content" do
  include ActiveSupport::Testing::TimeHelpers

  before { travel_to UrlContract::FROZEN_AT }
  after { travel_back }

  include_context "with tenant domain"
  let(:tenant_domain_attributes) { { name: "contract", title: "Contract Site", description: "Contract description" } }

  let!(:scholar) { create(:scholar, full_name: "محمد الهاجري", first_name: "محمد", last_name: "الهاجري") }
  let!(:book) { on_domain(create(:book, id: UrlContract::BOOK_ID, scholar: scholar, title: "كتاب التوحيد", description: "وصف الكتاب")) }
  let!(:article) { on_domain(create(:article, id: UrlContract::ARTICLE_ID, scholar: scholar, title: "مقالة في العقيدة")) }
  let!(:series) { on_domain(create(:series, id: UrlContract::SERIES_ID, scholar: scholar, title: "شرح الأصول الثلاثة", description: "وصف السلسلة")) }
  let!(:lesson) do
    on_domain(create(:lesson, id: UrlContract::LESSON_ID, series: series, title: "الدرس الأول", description: "وصف الدرس", position: 1, duration: 45))
  end
  let!(:news) { on_domain(create(:news, id: UrlContract::NEWS_ID, scholar: scholar, title: "خبر الدرس الجديد", description: "وصف الخبر")) }
  let!(:fatwa) { on_domain(create(:fatwa, id: UrlContract::FATWA_ID, scholar: scholar, title: "حكم صلاة الجماعة")) }
  let!(:sermon) { on_domain(create(:lecture, id: UrlContract::SERMON_ID, scholar: scholar, kind: :sermon, title: "خطبة الجمعة", description: "وصف الخطبة", duration: 60)) }
  let!(:conference) do
    on_domain(create(:lecture, id: UrlContract::CONFERENCE_ID, scholar: scholar, kind: :conference, title: "محاضرة العلم", description: "وصف المحاضرة", duration: 90))
  end
  let!(:benefit) { on_domain(create(:lecture, id: UrlContract::BENEFIT_ID, scholar: scholar, kind: :benefit, title: "فائدة في النية", description: "وصف الفائدة", duration: 30)) }

  def on_domain(record)
    record.domains = [ domain ]
    record.save!
    record
  end

  def absolute(path, host: tenant_host)
    "http://#{host}#{path}"
  end
end
