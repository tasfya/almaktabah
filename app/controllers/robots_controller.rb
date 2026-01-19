# frozen_string_literal: true

class RobotsController < ApplicationController
  def show
    render plain: <<~ROBOTS
      User-agent: *
      Allow: /
      Disallow: /avo/
      Disallow: /jobs/

      Sitemap: #{request.protocol}#{request.host_with_port}/sitemap.xml
    ROBOTS
  end
end
