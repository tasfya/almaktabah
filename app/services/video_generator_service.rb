class VideoGeneratorService
  attr_reader :title, :description, :audio_file, :logo_file, :temp_dir

  include ArabicHelper

  def initialize(title:, description: nil, audio_file:, logo_file:)
    @title = title
    @description = description
    @audio_file = audio_file
    @logo_file = logo_file
    @temp_dir = nil
  end

  def call
    setup_temp_directory

    begin
      mp3_path  = copy_file_to_temp(audio_file, "audio.mp3")
      logo_path = copy_file_to_temp(logo_file,  "logo.png")

      background_path = create_background_image(logo_path, temp_dir.join("background.png"))
      output_path     = temp_dir.join("output.mp4")
      generate_video(mp3_path, background_path, output_path)

      {
        success: true,
        video_path: output_path.to_s,
        filename: "#{transliterate_arabic(title).parameterize}.mp4"
      }
    rescue => e
      Rails.logger.error "Video generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end
  end

  def cleanup!
    FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
  end

  private

  def setup_temp_directory
    @temp_dir = Rails.root.join("tmp", "video_generation", SecureRandom.uuid)
    FileUtils.mkdir_p(@temp_dir)
  end

  def copy_file_to_temp(file, filename)
    temp_path = temp_dir.join(filename)

    if file.respond_to?(:download)
      File.open(temp_path, "wb") { |f| file.download { |chunk| f.write(chunk) } }
    elsif file.respond_to?(:read)
      File.open(temp_path, "wb") { |f| file.rewind if file.respond_to?(:rewind); f.write(file.read) }
    elsif file.is_a?(String) && File.exist?(file)
      FileUtils.cp(file, temp_path)
    else
      raise ArgumentError, "Unsupported file type: #{file.class}"
    end

    temp_path.to_s
  end

  def create_background_image(logo_path, output_path)
    require "mini_magick"

    canvas_path = temp_dir.join("canvas.png")
    system(["convert", "-size", "1920x1080", "canvas:#1a1a1a", canvas_path.to_s])

    image = MiniMagick::Image.new(canvas_path.to_s)
    image = add_logo_to_image(image, logo_path)
    image = add_title_text_to_image(image, title)
    image = add_description_text_to_image(image, description) if description.present?

    image.write(output_path.to_s)
    output_path.to_s
  end

  def add_logo_to_image(base_image, logo_path)
    return base_image unless File.exist?(logo_path)
    logo = MiniMagick::Image.open(logo_path)
    logo.resize "400x400>"
    x_offset = (1920 - logo.width) / 2
    base_image.composite(logo) { |c| c.compose "Over"; c.geometry "+#{x_offset}+150" }
  rescue => e
    Rails.logger.warn "Logo processing failed: #{e.message}"
    base_image
  end

  def add_title_text_to_image(image, text)
    return image if text.blank?
    if arabic_text?(text)
      add_text(image, text, y_position: 600, font_size: 48, color: "white", arabic: true)
    else
      add_text(image, text, y_position: 600, font_size: 48, color: "white")
    end
  end

  def add_description_text_to_image(image, text)
    return image if text.blank?
    if arabic_text?(text)
      add_text(image, text, y_position: 750, font_size: 32, color: "#cccccc", arabic: true)
    else
      add_text(image, text, y_position: 750, font_size: 32, color: "#cccccc")
    end
  end

  def add_text(image, text, y_position:, font_size:, color:, font: "ScheherazadeNew-Regular.ttf", arabic: true)
    font_path = Rails.root.join("app/assets/fonts", font)

    wrapped = arabic ? arabic_word_wrap(text, 40) : word_wrap(text, 50)

    image.combine_options do |c|
      c.font font_path.to_s
      c.fill color
      c.pointsize font_size.to_s
      c.gravity "center"
      c.size "1800x300"
      c.background "transparent"
      c.annotate "+0+#{y_position - 540}", wrapped
    end
    image
  rescue => e
    Rails.logger.error "Text rendering failed: #{e.message}"
    image
  end

  def arabic_word_wrap(text, max_chars)
    words, lines, current, length = text.split(/\s+/), [], [], 0
    words.each do |w|
      if length + w.length + 1 <= max_chars && !current.empty?
        current << w; length += w.length + 1
      else
        lines << current.join(" ") unless current.empty?
        current, length = [w], w.length
      end
    end
    lines << current.join(" ") unless current.empty?
    lines.join("\n")
  end

  def word_wrap(text, max_chars)
    words, lines, current = text.split(" "), [], []
    words.each do |w|
      test_line = (current + [w]).join(" ")
      if test_line.length <= max_chars
        current << w
      else
        lines << current.join(" ") unless current.empty?
        current = [w]
      end
    end
    lines << current.join(" ") unless current.empty?
    lines.join("\n")
  end

  def arabic_text?(text)
    text.present? && text.match?(/[\u0600-\u06FF]/)
  end

  def generate_video(mp3_path, background_path, output_path)
    require "streamio-ffmpeg"
    duration = FFMPEG::Movie.new(mp3_path).duration
    ffmpeg_command = [
      "ffmpeg", "-loop", "1", "-i", background_path,
      "-i", mp3_path, "-c:v", "libx264", "-tune", "stillimage",
      "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p",
      "-shortest", "-t", duration.to_s, "-y", output_path.to_s
    ]
    Open3.popen3(*ffmpeg_command) { |_i,_o,e,t| raise "FFmpeg failed: #{e.read}" unless t.value.success? }
  end
end
