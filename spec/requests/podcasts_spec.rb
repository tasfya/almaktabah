# spec/requests/podcasts_spec.rb

require 'rails_helper'

RSpec.describe "Podcast Feeds", type: :request do
  let!(:lesson) { create(:lesson, published: true, title: "Test Lesson", description: "Lesson summary") }
  let!(:lecture) { create(:lecture, published: true, title: "Test Lecture", description: "Lecture summary") }
  before do
    @domain = create(:domain, host: "www.example.com")
    lesson.assign_to(@domain)
    lecture.assign_to(@domain)
    @headers = { "HTTP" => @domain.host }
  end
  describe "GET /podcasts/feed" do
    it "returns XML RSS feed" do
      get '/podcasts/feed', headers: @headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/xml; charset=utf-8')
      expect(response.body).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(response.body).to include('<rss version="2.0"')
      expect(response.body).to include('محمد بن رمزان الهاجري')
    end

    it "includes lesson and lecture items" do
      get '/podcasts/feed', headers: @headers

      expect(response.body).to include('Test Lesson')
      expect(response.body).to include('Test Lecture')
      expect(response.body).to include('Lesson summary')
      expect(response.body).to include('Lecture summary')
    end

    it "includes required RSS elements" do
      get '/podcasts/feed', headers: @headers

      expect(response.body).to include('<channel>')
      expect(response.body).to include('<title>')
      expect(response.body).to include('<description>')
      expect(response.body).to include('<itunes:author>')
      expect(response.body).to include('<enclosure')
      expect(response.body).to include('<pubDate>')
    end
  end


  describe "RSS feed validation" do
    before { get '/podcasts/feed', headers: @headers }


    it "has valid RSS structure" do
      doc = Nokogiri::XML(response.body)

      expect(doc.xpath('//rss')).to be_present
      expect(doc.xpath('//channel')).to be_present
      expect(doc.xpath('//item')).to be_present
    end

    it "includes iTunes namespace" do
      expect(response.body).to include('xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"')
    end

    it "includes Spotify namespace" do
      expect(response.body).to include('xmlns:spotify="http://www.spotify.com/ns/rss"')
    end

    it "includes content namespace" do
      expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
    end
  end

  describe "episode elements" do
    before do
      # Create lesson with specific attributes for testing
      lesson = create(:lesson, published: true,
        title: "Episode Title",
        description: "Episode Description",
        duration: Time.zone.parse("00:45:30"),
        published_at: Time.zone.parse("2024-01-15 10:00:00")
      )
      lesson.assign_to(@domain)
      get '/podcasts/feed', headers: @headers
    end

    it "includes episode title" do
      expect(response.body).to include('Episode Title')
    end

    it "includes episode description" do
      expect(response.body).to include('<description>Episode Description</description>')
    end

    it "includes enclosure tag with audio details" do
      expect(response.body).to include('audio.mp3"')
      expect(response.body).to include('length="')
      expect(response.body).to include('type="audio/mpeg"')
    end

    it "includes iTunes duration" do
      expect(response.body).to include('<itunes:duration>00:45:30</itunes:duration>')
    end

    it "includes publication date in RFC-822 format" do
      expect(response.body).to match(/<pubDate>.*2024.*<\/pubDate>/)
    end
  end
end
