# frozen_string_literal: true

class RobotsController < ApplicationController
  def show
    # Set on non-production deploys (staging) so crawlers never index them.
    return render plain: "User-agent: *\nDisallow: /\n" if ENV["DISALLOW_ROBOTS"].present?

    render plain: <<~ROBOTS
      User-agent: *
      Allow: /
      Disallow: /avo/
      Disallow: /jobs/

      Sitemap: #{request.protocol}#{request.host_with_port}/sitemap.xml
    ROBOTS
  end
end
