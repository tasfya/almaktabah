# frozen_string_literal: true

class RobotsController < ApplicationController
  def show
    render plain: <<~ROBOTS
      User-agent: *
      Allow: /
      Disallow: /avo/
      Disallow: /jobs/

      Sitemap: #{request.protocol}#{request.host}/sitemap.xml
    ROBOTS
  end
end
