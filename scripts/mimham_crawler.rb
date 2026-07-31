#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'net/http'
require 'uri'

class MimhamCrawler
  BASE_URL = 'https://www.mimham.net'

  SECTIONS = {
    'khotab' => { url: "#{BASE_URL}/section-khotab-0-0", kind: 'sermon' },
    'mohad' => { url: "#{BASE_URL}/section-mohad-0-0", kind: 'conference' }
  }.freeze

  def initialize(section:, output_file: nil)
    @section = section
    @config = SECTIONS[section] || raise("Unknown section: #{section}. Available: #{SECTIONS.keys.join(', ')}")
    @output_file = output_file || "mimham_#{section}.csv"
    @items = []
  end

  def crawl
    puts "Starting crawl from #{@config[:url]}"

    html = fetch_page(@config[:url])
    unless html
      puts "Failed to fetch page"
      return
    end

    doc = Nokogiri::HTML(html)
    extract_items(doc)

    puts "Found #{@items.length} items"
    write_csv
    puts "Done! Wrote #{@items.length} items to #{@output_file}"
  end

  private

  def fetch_page(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 120

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      response.body.force_encoding('UTF-8')
    when Net::HTTPRedirection
      fetch_page(response['location'])
    else
      puts "Error fetching #{url}: #{response.code}"
      nil
    end
  rescue StandardError => e
    puts "Error fetching #{url}: #{e.message}"
    nil
  end

  def extract_items(doc)
    doc.css('table#example tbody tr').each do |row|
      cells = row.css('td')
      next if cells.length < 6

      # Title
      title_link = cells[0].css('a').first
      title = title_link&.text&.strip || cells[0].text.strip
      source_url = title_link ? normalize_url(title_link['href']) : nil

      # Scholar
      scholar_link = cells[1].css('a').first
      scholar_name = scholar_link&.text&.strip || cells[1].text.strip

      # Category
      category_link = cells[2].css('a').first
      category = category_link&.text&.strip || cells[2].text.strip

      # Date
      date = cells[3].text.strip

      # Download link - look for icon-download in column 5
      download_link = cells[5].css('a').first
      audio_url = download_link ? normalize_url(download_link['href']) : nil

      @items << {
        title: title,
        scholar_name: scholar_name,
        category: category,
        published_at: date,
        kind: @config[:kind],
        source_url: source_url,
        audio_url: audio_url
      }
    end
  end

  def normalize_url(href)
    return nil unless href
    href = href.strip
    return href if href.start_with?('http')
    href = "/#{href}" unless href.start_with?('/')
    "#{BASE_URL}#{href}"
  end

  def write_csv
    CSV.open(@output_file, 'w', encoding: 'UTF-8') do |csv|
      # Header row for importer
      csv << [ 'title', 'scholar_name', 'category', 'published_at', 'kind', 'source_url', 'audio_url' ]

      @items.each do |item|
        csv << [
          item[:title],
          item[:scholar_name],
          item[:category],
          item[:published_at],
          item[:kind],
          item[:source_url],
          item[:audio_url]
        ]
      end
    end
  end
end

# Run the crawler
if __FILE__ == $PROGRAM_NAME
  section = ARGV[0] || 'khotab'
  output_file = ARGV[1]

  if section == 'all'
    MimhamCrawler::SECTIONS.each_key do |s|
      crawler = MimhamCrawler.new(section: s)
      crawler.crawl
      puts
    end
  else
    crawler = MimhamCrawler.new(section: section, output_file: output_file)
    crawler.crawl
  end
end
