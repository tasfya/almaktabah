#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'csv'
require 'net/http'
require 'uri'

class MimhamSeriesCrawler
  BASE_URL = 'https://www.mimham.net'
  SERIES_URL = "#{BASE_URL}/section-charhall-0"

  def initialize(output_file: nil, fetch_lessons: false)
    @output_file = output_file || 'mimham_series.csv'
    @fetch_lessons = fetch_lessons
    @series = []
    @lessons = []
  end

  def crawl
    puts "Starting crawl from #{SERIES_URL}"

    html = fetch_page(SERIES_URL)
    unless html
      puts "Failed to fetch page"
      return
    end

    doc = Nokogiri::HTML(html)
    extract_series(doc)

    puts "Found #{@series.length} series"

    if @fetch_lessons
      fetch_all_lessons
      write_lessons_csv
    else
      write_series_csv
    end

    puts "Done!"
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

  def extract_series(doc)
    doc.css('table#example tbody tr').each do |row|
      cells = row.css('td')
      next if cells.length < 5

      # Number/ID
      number = cells[0].text.strip

      # Series title and URL
      title_link = cells[1].css('a').first
      title = title_link&.text&.strip || cells[1].text.strip
      source_url = title_link ? normalize_url(title_link['href']) : nil

      # Scholar
      scholar_link = cells[2].css('a').first
      scholar_name = scholar_link&.text&.strip || cells[2].text.strip

      # Date
      date = cells[3].text.strip

      # Lessons count
      lessons_count = cells[4].text.strip.to_i

      @series << {
        number: number,
        title: title,
        scholar_name: scholar_name,
        published_at: date,
        lessons_count: lessons_count,
        source_url: source_url
      }
    end
  end

  def fetch_all_lessons
    total = @series.length
    @series.each_with_index do |series, index|
      puts "Fetching lessons for series #{index + 1}/#{total}: #{series[:title]}"

      next unless series[:source_url]

      html = fetch_page(series[:source_url])
      next unless html

      doc = Nokogiri::HTML(html)
      extract_lessons(doc, series)

      # Be polite to the server
      sleep(0.5)
    end

    puts "Total lessons found: #{@lessons.length}"
  end

  def extract_lessons(doc, series)
    doc.css('table#example tbody tr').each do |row|
      cells = row.css('td')
      next if cells.length < 5

      # Column structure:
      # 0: Lesson number
      # 1: Lesson title (link to dar-*)
      # 2: Date
      # 3: File size
      # 4: Duration
      # 5: Listen count
      # 6: Download count
      # 7: Download link (tan-*)
      # 8: Transcription link

      # Lesson number
      lesson_number = cells[0].text.strip

      # Lesson title and URL
      title_link = cells[1].css('a').first
      title = title_link&.text&.strip || cells[1].text.strip
      lesson_url = title_link ? normalize_url(title_link['href']) : nil

      # Date
      date = cells[2].text.strip

      # File size
      file_size = cells[3].text.strip

      # Duration
      duration = cells[4].text.strip

      # Audio download link - look for link with title="تحميل" (serves MP3 directly)
      audio_link = row.css('a[title="تحميل"]').first
      audio_url = audio_link ? normalize_url(audio_link['href']) : nil

      @lessons << {
        series_title: series[:title],
        scholar_name: series[:scholar_name],
        lesson_number: lesson_number,
        title: title,
        published_at: date,
        file_size: file_size,
        duration: duration,
        kind: 'lesson',
        source_url: lesson_url,
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

  def write_series_csv
    CSV.open(@output_file, 'w', encoding: 'UTF-8') do |csv|
      csv << [ 'number', 'title', 'scholar_name', 'published_at', 'lessons_count', 'source_url' ]

      @series.each do |item|
        csv << [
          item[:number],
          item[:title],
          item[:scholar_name],
          item[:published_at],
          item[:lessons_count],
          item[:source_url]
        ]
      end
    end

    puts "Wrote #{@series.length} series to #{@output_file}"
  end

  def write_lessons_csv
    lessons_file = @output_file.sub('.csv', '_lessons.csv')

    CSV.open(lessons_file, 'w', encoding: 'UTF-8') do |csv|
      csv << [ 'series_title', 'scholar_name', 'lesson_number', 'title', 'published_at', 'file_size', 'duration', 'kind', 'source_url', 'audio_url' ]

      @lessons.each do |item|
        csv << [
          item[:series_title],
          item[:scholar_name],
          item[:lesson_number],
          item[:title],
          item[:published_at],
          item[:file_size],
          item[:duration],
          item[:kind],
          item[:source_url],
          item[:audio_url]
        ]
      end
    end

    puts "Wrote #{@lessons.length} lessons to #{lessons_file}"

    # Also write the series summary
    write_series_csv
  end
end

# Run the crawler
if __FILE__ == $PROGRAM_NAME
  fetch_lessons = ARGV.include?('--lessons')
  output_file = ARGV.find { |arg| !arg.start_with?('--') }

  crawler = MimhamSeriesCrawler.new(
    output_file: output_file,
    fetch_lessons: fetch_lessons
  )
  crawler.crawl
end
