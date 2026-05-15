class PodcastsController < ApplicationController
  include PodcastsHelper

  def feed
    unless @domain.podcast_enabled?
      head :not_found
      return
    end

    @podcast = get_podcast_detail(domain: @domain)
    @episodes = get_podcast_audios(domain_id: @domain.id)
    @host = @domain.host
    @feed_url = "https://#{@domain.host}/podcasts/feed"

    respond_to do |format|
      format.rss { render :feed, layout: false, content_type: "application/rss+xml" }
      format.xml { render :feed, layout: false, content_type: "application/rss+xml" }
    end
  end
end
