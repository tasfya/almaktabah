# app/views/podcasts/show.xml.builder
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0",
        "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:spotify" => "http://www.spotify.com/ns/rss" do
  xml.channel do
    # --- Podcast Channel Info ---
    xml.title @podcast[:title]
    xml.link @podcast[:website_url] # Link to your podcast's website
    xml.language "en-us"
    xml.copyright "© #{Time.now.year} #{@podcast[:author]}"
    xml.tag! "itunes:author", @podcast[:author]
    xml.tag! "itunes:summary", @podcast[:description]
    xml.description @podcast[:description]

    # Explicit content setting (yes/no/clean)
    xml.tag! "itunes:explicit", "no"

    # Podcast artwork
    xml.tag! "itunes:image", href: @podcast[:artwork_url]

    # Podcast category
    xml.tag! "itunes:category", text: "Education"

    # Spotify recent episode limit (optional, but good practice)
    xml.tag! "spotify:limit", recentCount: 20

    # --- Episodes ---
    @episodes.each do |episode|
      xml.item do
        xml.title episode.podcast_title
        xml.tag! "itunes:author", @podcast[:author]
        xml.tag! "itunes:summary", episode.summary
        xml.description episode.summary

        # Enclosure tag is crucial for the audio file
        xml.enclosure url: scheme + "://" + @host + episode.audio_url, length: episode.audio_file_size, type: "audio/mpeg"

        # A unique identifier for the episode
        xml.guid @scheme + "://" + @host + episode.audio_url, isPermaLink: "true"

        # Publication date (must be RFC-822 format)
        xml.pubDate episode.published_at.rfc2822

        # Episode duration in HH:MM:SS format
        xml.tag! "itunes:duration", Time.at(episode.duration).utc.strftime("%H:%M:%S")

        # Explicit content setting for the episode
        xml.tag! "itunes:explicit", "no"
      end
    end
  end
end
