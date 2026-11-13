module TelegramImport
  module VideoId
    PATTERN = %r{(?:youtu\.be/|[?&]v=|youtube\.com/live/|youtube\.com/embed/|youtube\.com/shorts/)([\w-]{11})}

    def self.extract(url)
      url.to_s[PATTERN, 1]
    end

    def self.watch_url(id)
      "https://www.youtube.com/watch?v=#{id}"
    end
  end
end
