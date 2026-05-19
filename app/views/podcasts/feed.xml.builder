xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0",
        "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
        "xmlns:atom" => "http://www.w3.org/2005/Atom",
        "xmlns:spotify" => "http://www.spotify.com/ns/rss" do
  xml.channel do
    # Required: Self-referencing atom link for feed validation
    xml.tag! "atom:link", href: @feed_url, rel: "self", type: "application/rss+xml"

    # Required channel tags
    xml.title @podcast[:title]
    xml.link @podcast[:website_url]
    xml.description @podcast[:description]
    xml.language @podcast[:language]
    xml.copyright "© #{Time.now.year} #{@podcast[:author]}"

    # iTunes/Spotify required tags
    xml.tag! "itunes:author", @podcast[:author]
    xml.tag! "itunes:summary", @podcast[:description]
    xml.tag! "itunes:type", "episodic"
    xml.tag! "itunes:explicit", "false"

    # iTunes owner (required for submission)
    xml.tag! "itunes:owner" do
      xml.tag! "itunes:name", @podcast[:owner_name]
      xml.tag! "itunes:email", @podcast[:owner_email]
    end

    # Podcast artwork (minimum 1400x1400, maximum 3000x3000, JPEG or PNG)
    xml.tag! "itunes:image", href: @podcast[:artwork_url]
    xml.image do
      xml.url @podcast[:artwork_url]
      xml.title @podcast[:title]
      xml.link @podcast[:website_url]
    end

    # Category with subcategory
    xml.tag! "itunes:category", text: @podcast[:category] do
      xml.tag! "itunes:category", text: @podcast[:subcategory] if @podcast[:subcategory].present?
    end

    # Episodes
    @episodes.each do |episode|
      xml.item do
        xml.title episode.podcast_title
        xml.description do
          xml.cdata! episode.summary.to_s
        end
        xml.tag! "content:encoded" do
          xml.cdata! episode.summary.to_s
        end

        xml.tag! "itunes:author", @podcast[:author]
        xml.tag! "itunes:summary", episode.summary
        xml.tag! "itunes:explicit", "false"
        xml.tag! "itunes:episodeType", "full"

        # Episode and season numbers for lessons (helps podcast apps order episodes correctly)
        if episode.is_a?(Lesson)
          xml.tag! "itunes:episode", episode.position
          xml.tag! "itunes:season", episode.series_id
        end

        # Enclosure (the actual audio file)
        xml.enclosure url: episode.podcast_audio_url,
                      length: episode.audio_file_size.to_i,
                      type: "audio/mpeg"

        # GUID must be unique and permanent (using model type + id)
        xml.guid "#{episode.class.name.downcase}-#{episode.id}@#{@host}", isPermaLink: "false"

        # Publication date in RFC-822 format
        xml.pubDate episode.published_at.to_datetime.rfc2822

        # Duration in seconds (Spotify prefers seconds, iTunes accepts both)
        xml.tag! "itunes:duration", episode.duration.to_i

        # Link to episode page (required)
        xml.link episode.podcast_episode_url || @podcast[:website_url]
      end
    end
  end
end
