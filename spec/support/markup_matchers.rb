# frozen_string_literal: true

# Matchers that parse HTML/XML instead of grepping the raw body. Each accepts a
# response or a string, and each expected value may be a composable matcher:
#
#   expect(response).to have_html_title(a_string_starting_with("Book title"))
#   expect(response).to have_meta_tag("og:type", "article")
#   expect(response).to have_canonical("http://localhost/books/x")
#   expect(response).to have_sitemap_locs("http://localhost/", "http://localhost/about")
#   expect(sitemap_locs).to eq([...])
#   expect(json_ld).to include(a_hash_including("@type" => "Article"))
module MarkupHelpers
  module_function

  def markup_of(subject)
    subject.respond_to?(:body) ? subject.body : subject.to_s
  end

  def parse_html(subject)
    Nokogiri::HTML(markup_of(subject))
  end

  def sitemap_locs(subject = response)
    Nokogiri::XML(markup_of(subject)).remove_namespaces!.xpath("//loc").map { |loc| loc.text.strip }
  end

  def json_ld(subject = response)
    parse_html(subject).css('script[type="application/ld+json"]').flat_map { |script| Array.wrap(JSON.parse(script.text)) }
  end
end

RSpec::Matchers.define :have_html_title do |expected|
  match do |actual|
    @title = MarkupHelpers.parse_html(actual).at_css("head title")&.text&.strip
    values_match?(expected, @title)
  end

  failure_message { "expected <title> to match #{description_of(expected)}, got #{@title.inspect}" }
end

# Looks up <meta name="..."> or <meta property="..."> (Open Graph).
RSpec::Matchers.define :have_meta_tag do |key, expected_content = nil|
  match do |actual|
    tag = MarkupHelpers.parse_html(actual).at_css(%(meta[name="#{key}"], meta[property="#{key}"]))
    @found = !tag.nil?
    @content = tag&.[]("content")
    @found && (expected_content.nil? || values_match?(expected_content, @content))
  end

  failure_message do
    if !@found
      "expected a <meta> tag named #{key.inspect}, found none"
    else
      "expected <meta #{key}> content to match #{description_of(expected_content)}, got #{@content.inspect}"
    end
  end
end

RSpec::Matchers.define :have_canonical do |expected|
  match do |actual|
    @href = MarkupHelpers.parse_html(actual).at_css('link[rel="canonical"]')&.[]("href")
    values_match?(expected, @href)
  end

  failure_message { "expected canonical link to match #{description_of(expected)}, got #{@href.inspect}" }
end

# Passes when every expected URL is among the sitemap's <loc> entries.
RSpec::Matchers.define :have_sitemap_locs do |*expected|
  match do |actual|
    @locs = MarkupHelpers.sitemap_locs(actual)
    expected.all? { |url| @locs.any? { |loc| values_match?(url, loc) } }
  end

  failure_message { "expected sitemap <loc>s to include #{expected.inspect}, got #{@locs.inspect}" }
end

# Passes for the not-found page of a missing record: status 404, the message
# in the page, a link back to the listing, and a response no cache may keep
# (the record may be published later).
#
#   expect(response).to be_not_found_page(I18n.t("messages.book_not_found"), back_to: books_path)
RSpec::Matchers.define :be_not_found_page do |message, back_to:|
  match do |response|
    page = MarkupHelpers.parse_html(response)
    @status = response.status
    @cache_control = response.headers["Cache-Control"]
    @message_found = page.at_css("main")&.text.to_s.include?(message)
    @back_found = page.css("main a").any? { |a| CGI.unescape(a["href"].to_s) == CGI.unescape(back_to) }
    @status == 404 && @message_found && @back_found && @cache_control.to_s.include?("no-store")
  end

  failure_message do
    "expected a 404 not-found page with #{message.inspect} and a link to #{back_to}, " \
      "got status #{@status}, message #{@message_found ? "present" : "missing"}, " \
      "link #{@back_found ? "present" : "missing"}, Cache-Control #{@cache_control.inspect}"
  end
end

RSpec.configure do |config|
  config.include MarkupHelpers, type: :request
end
