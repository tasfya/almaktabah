# frozen_string_literal: true

module RequestHelpers
  def html
    Nokogiri::HTML(response.body)
  end

  # [name, href] for each rendered breadcrumb after the home link that every
  # page starts with; href is nil for the current page.
  def breadcrumb_trail
    crumbs = html.css(".breadcrumbs li").map do |li|
      link = li.at_css("a")
      [ li.text.strip, link&.[]("href") ]
    end
    crumbs.first&.last == root_path ? crumbs.drop(1) : crumbs
  end

  def search_page_rendered?
    html.at_css("turbo-frame#search_content").present?
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
