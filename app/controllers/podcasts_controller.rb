class PodcastsController < ApplicationController
  include PodcastsHelper
  def feed
    @podcast = get_podcast_detail()
    @episodes = get_podcast_audios(domain_id: @domain.id)
    @host = @domain.host
    @scheme = request.scheme
    respond_to do |format|
        format.rss { render layout: false }
        format.xml { render :feed, layout: false }
    end
  end
end
