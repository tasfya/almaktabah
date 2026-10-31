# frozen_string_literal: true

require "rails_helper"

# A visitor opens a record and listens, watches, reads or downloads it. The
# player and missing-media specs check the markup; these follow the links a
# browser would follow (play form, <audio src>, <video><source src>, download
# buttons) through to the file itself, so a broken route, a wrong attachment or
# an unservable blob fails here instead of leaving a dead button.
RSpec.describe "Journey: listen to, watch and download a record", type: :request do
  include_context "with tenant domain"

  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  def on_domain(record)
    record.tap { |r| r.update!(domains: [ domain ]) }
  end

  # Follows a media URL through Active Storage's redirects to the bytes.
  def fetch(url)
    get url
    follow_redirect! while response.redirect?
    response
  end

  def expect_served(url, content_type)
    expect(url).to be_present
    served = fetch(url)
    expect(served).to have_http_status(:ok)
    expect(served.media_type).to eq(content_type)
    expect(served.body).not_to be_empty
  end

  def download_links
    html.css("a[download]").map { |a| a["href"] }
  end

  # Submits the page's play button the way its turbo-stream form does and
  # returns the player fragment.
  def play_from_page
    form = html.at_css("form[data-controller='play-button']")
    expect(form).to be_present
    get form["action"], headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body)
  end

  def expect_player_streams_audio
    audio = play_from_page.at_css("audio[src]")
    expect(audio).to be_present
    expect_served(audio["src"], "audio/mpeg")
  end

  it "plays, watches and downloads a lecture" do
    lecture = on_domain(create(:lecture, title: "Media Lecture", scholar: scholar))

    get lecture_path(scholar, lecture, kind: lecture.kind_for_url)
    expect(response).to have_http_status(:ok)
    video_src = html.at_css("article video source")["src"]
    downloads = download_links
    expect(downloads.size).to eq(2)

    expect_served(video_src, "video/mp4")
    expect_served(downloads.first, "audio/mpeg")
    expect_served(downloads.last, "video/mp4")

    get lecture_path(scholar, lecture, kind: lecture.kind_for_url)
    expect_player_streams_audio
  end

  it "opens a series, then a lesson, and plays it" do
    series = on_domain(create(:series, title: "Media Series", scholar: scholar))
    lesson = on_domain(create(:lesson, title: "Media Lesson", series: series))

    get series_path(scholar, series)
    expect(response).to have_http_status(:ok)
    lesson_link = html.css("a[href]").map { |a| a["href"] }.find { |href| href == series_lesson_path(scholar, series, lesson) }
    expect(lesson_link).to be_present

    get lesson_link
    expect(response).to have_http_status(:ok)
    expect(html.at_css("h1")&.text.to_s.strip).to eq("Media Lesson")
    expect_served(download_links.first, "audio/mpeg")

    get lesson_link
    expect_player_streams_audio
  end

  it "plays a lesson straight from the series page" do
    series = on_domain(create(:series, title: "Media Series", scholar: scholar))
    on_domain(create(:lesson, title: "Media Lesson", series: series))

    get series_path(scholar, series)
    expect_player_streams_audio
  end

  it "plays and watches a fatwa" do
    fatwa = on_domain(create(:fatwa, title: "Media Fatwa", scholar: scholar, published_at: 1.day.ago))

    get fatwa_path(scholar, fatwa)
    expect(response).to have_http_status(:ok)
    expect_served(html.at_css("article video source")["src"], "video/mp4")

    get fatwa_path(scholar, fatwa)
    expect_player_streams_audio
  end

  it "downloads a book's PDF" do
    book = on_domain(create(:book, title: "Media Book", scholar: scholar))

    get book_path(scholar, book)
    expect(response).to have_http_status(:ok)
    pdf_link = html.at_css("article a[target='_blank'][href*='/rails/active_storage/']")
    expect(pdf_link).to be_present

    expect_served(pdf_link["href"], "application/pdf")
  end

  # Current behaviour, not the goal (#636): the page stays up, but its download
  # button leads to a 404 because nothing checks that the object still exists.
  it "keeps the book page up when its PDF object is gone" do
    book = on_domain(create(:book, title: "Media Book", scholar: scholar))
    File.delete(ActiveStorage::Blob.service.path_for(book.file.blob.key))

    get book_path(scholar, book)
    expect(response).to have_http_status(:ok)
    pdf_link = html.at_css("article a[target='_blank'][href*='/rails/active_storage/']")
    expect(pdf_link).to be_present

    expect(fetch(pdf_link["href"])).to have_http_status(:not_found)
  end
end
