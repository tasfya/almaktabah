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
      mp3_path = copy_file_to_temp(audio_file, "audio.mp3")
      logo_path = copy_file_to_temp(logo_file, "logo.png")

      background_path = create_background_image(logo_path, temp_dir.join("background.png"))

      output_path = temp_dir.join("output.mp4")
      generate_video(mp3_path, background_path, output_path)

      {
        success: true,
        video_path: output_path.to_s,
        filename: "#{transliterate_arabic(title).parameterize}.mp4"
      }
    rescue => e
      Rails.logger.error "Video generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      {
        success: false,
        error: e.message
      }
    ensure
      # Note: Don't clean up temp files here since caller might need the video
      # Caller should handle cleanup
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
      # Handle Active Storage attachment
      File.open(temp_path, "wb") do |temp_file|
        file.download { |chunk| temp_file.write(chunk) }
      end
    elsif file.respond_to?(:read)
      # Handle uploaded file or IO object
      File.open(temp_path, "wb") do |temp_file|
        file.rewind if file.respond_to?(:rewind)
        temp_file.write(file.read)
      end
    elsif file.is_a?(String) && File.exist?(file)
      # Handle file path
      FileUtils.cp(file, temp_path)
    else
      raise ArgumentError, "Unsupported file type: #{file.class}"
    end

    temp_path.to_s
  end


  def create_background_image(logo_path, output_path)
    create_background_with_imagemagick(logo_path, output_path)
  end

  def create_background_with_imagemagick(logo_path, output_path)
    require "mini_magick"

    # Create base canvas using convert command
    canvas_path = temp_dir.join("canvas.png")
    system("convert -size 1920x1080 canvas:#1a1a1a #{canvas_path}")

    # Open the created canvas
    image = MiniMagick::Image.new(canvas_path.to_s)

    # Add logo
    image = add_logo_to_image(image, logo_path)

    # Add title text
    image = add_title_text_to_image(image, title)

    # Add description text
    image = add_description_text_to_image(image, description) if description.present?

    # Write final image
    image.write(output_path.to_s)
    output_path.to_s
  end

  def add_logo_to_image(base_image, logo_path)
    return base_image unless File.exist?(logo_path)

    begin
      # Create logo overlay
      logo = MiniMagick::Image.open(logo_path)

      # Resize logo to fit within 400x400 while maintaining aspect ratio
      logo.resize "400x400>"

      logo_width = logo.width
      x_offset = (1920 - logo_width) / 2
      y_offset = 150

      # Composite logo onto base image
      base_image = base_image.composite(logo) do |c|
        c.compose "Over"
        c.geometry "+#{x_offset}+#{y_offset}"
      end
    rescue => e
      Rails.logger.warn "Logo processing failed: #{e.message}"
      # Continue without logo
    end

    base_image
  end

  def add_title_text_to_image(image, text)
    return image if text.blank?

    if arabic_text?(text)
      add_arabic_text_to_image(image, text, y_position: 600, font_size: 48, color: "white")
    else
      add_latin_text_to_image(image, text, y_position: 600, font_size: 48, color: "white")
    end
  end

  def add_description_text_to_image(image, text)
    return image if text.blank?

    if arabic_text?(text)
      add_arabic_text_to_image(image, text, y_position: 750, font_size: 32, color: "#cccccc")
    else
      add_latin_text_to_image(image, text, y_position: 750, font_size: 32, color: "#cccccc")
    end
  end

  def add_arabic_text_to_image(image, text, y_position:, font_size:, color:)
    arabic_font = get_best_arabic_font
    if arabic_font&.include?("scheherazade")
      font_family = "Scheherazade"
    else
      font_family = arabic_font ? File.basename(arabic_font, File.extname(arabic_font)) : "DejaVu-Sans"
    end

    # Prepare text with proper escaping for Pango markup
    escaped_text = text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

    pango_markup = "<span font_family='#{font_family}' size='#{font_size * 1024}' foreground='#{color}'>#{escaped_text}</span>"

    begin
      # Use convert command directly for better Arabic support
      temp_text_path = temp_dir.join("arabic_text_#{SecureRandom.hex(8)}.png")

      # Create text image with transparent background
      convert_cmd = [
        "convert",
        "-background", "transparent",
        "-fill", color,
        "-font", arabic_font,
        "-pointsize", font_size.to_s,
        "-size", "1800x300",
        "-gravity", "center",
        "pango:#{pango_markup}",
        temp_text_path.to_s
      ]

      success = system(*convert_cmd)

      if success && File.exist?(temp_text_path)
        # Composite the text onto the main image
        text_image = MiniMagick::Image.open(temp_text_path.to_s)

        # Calculate position (center horizontally)
        x_offset = (1920 - text_image.width) / 2

        image = image.composite(text_image) do |c|
          c.compose "Over"
          c.geometry "+#{x_offset}+#{y_position}"
        end

        # Clean up temporary file
        File.delete(temp_text_path) if File.exist?(temp_text_path)
      else
        Rails.logger.warn "Pango text rendering failed, falling back to basic method"
        image = add_fallback_arabic_text(image, text, y_position, font_size, color)
      end

    rescue => e
      Rails.logger.error "Arabic text rendering failed: #{e.message}"
      image = add_fallback_arabic_text(image, text, y_position, font_size, color)
    end

    image
  end

  def add_latin_text_to_image(image, text, y_position:, font_size:, color:)
    font_path = get_latin_font_path
    wrapped_text = word_wrap(text, 50)

    begin
      image.combine_options do |c|
        c.font font_path if font_path
        c.fill color
        c.pointsize font_size.to_s
        c.gravity "center"
        c.size "1800x300"
        c.background "transparent"
        c.annotate "+0+#{y_position - 540}", wrapped_text  # Adjust for gravity center
      end
    rescue => e
      Rails.logger.error "Latin text rendering failed: #{e.message}"
    end

    image
  end

  def add_fallback_arabic_text(image, text, y_position, font_size, color)
    # Fallback method for Arabic text when Pango fails
    arabic_font = get_best_arabic_font
    wrapped_text = arabic_word_wrap(text, 40)

    begin
      image.combine_options do |c|
        c.font arabic_font if arabic_font
        c.fill color
        c.pointsize font_size.to_s
        c.gravity "center"
        c.size "1700x300"
        c.background "transparent"
        c.direction "right-to-left" if c.respond_to?(:direction)
        # Try to use Unicode normalization for better rendering
        normalized_text = wrapped_text.unicode_normalize(:nfc)
        c.annotate "+0+#{y_position - 540}", normalized_text
      end
    rescue => e
      Rails.logger.error "Fallback Arabic text rendering also failed: #{e.message}"
    end

    image
  end

  def arabic_word_wrap(text, max_chars)
    # Arabic word wrapping that preserves word boundaries
    words = text.split(/\s+/)
    lines = []
    current_line = []
    current_length = 0

    words.each do |word|
      word_length = word.length
      if current_length + word_length + 1 <= max_chars && !current_line.empty?
        current_line << word
        current_length += word_length + 1
      else
        lines << current_line.join(" ") unless current_line.empty?
        current_line = [ word ]
        current_length = word_length
      end
    end

    lines << current_line.join(" ") unless current_line.empty?
    lines.join("\n")
  end

  def get_best_arabic_font
    # Prioritized list of Arabic fonts with full paths
    arabic_fonts = [
      Rails.root.join("app/assets/fonts/Scheherazade_New/ScheherazadeNew-Regular.ttf").to_s,
      # Noto fonts (best for Arabic)
      "/usr/share/fonts/truetype/noto/NotoSansArabic-Regular.ttf",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
      "/usr/share/fonts/truetype/fonts-arabeyes/ae_AlArabiya.ttf",
      "/usr/share/fonts/truetype/kacst/KacstBook.ttf"
    ]

    best_font = arabic_fonts.find { |font| File.exist?(font) }

    if best_font.nil?
      font_names = [ "Noto Sans Arabic", "DejaVu Sans", "Liberation Sans", "Arial" ]
      font_names.each do |font_name|
        if test_font_availability(font_name)
          return font_name
        end
      end
    end

    best_font
  end

  def test_font_availability(font_name)
    cmd = [
      "convert",
      "-list", "font"
    ]

    begin
      result = `#{cmd.join(" ")}`.downcase
      result.include?(font_name.downcase)
    rescue
      false
    end
  end

  def get_latin_font_path
    latin_fonts = [
      "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    ]

    latin_fonts.find { |font| File.exist?(font) }
  end

  def generate_video(mp3_path, background_path, output_path)
    require "streamio-ffmpeg"

    # Get audio duration
    audio = FFMPEG::Movie.new(mp3_path)
    duration = audio.duration

    # FFmpeg command to create video
    ffmpeg_command = [
      "ffmpeg",
      "-loop", "1",
      "-i", background_path,
      "-i", mp3_path,
      "-c:v", "libx264",
      "-tune", "stillimage",
      "-c:a", "aac",
      "-b:a", "192k",
      "-pix_fmt", "yuv420p",
      "-shortest",
      "-t", duration.to_s,
      "-y",
      output_path.to_s
    ]

    # Execute FFmpeg
    Open3.popen3(*ffmpeg_command) do |stdin, stdout, stderr, thread|
      unless thread.value.success?
        error_output = stderr.read
        raise "FFmpeg failed: #{error_output}"
      end
    end
  end

  def word_wrap(text, max_chars)
    return arabic_word_wrap(text, max_chars) if arabic_text?(text)

    words = text.split(" ")
    lines = []
    current_line = []

    words.each do |word|
      test_line = (current_line + [ word ]).join(" ")
      if test_line.length <= max_chars
        current_line << word
      else
        lines << current_line.join(" ") unless current_line.empty?
        current_line = [ word ]
      end
    end

    lines << current_line.join(" ") unless current_line.empty?
    lines.join("\n")
  end

  # Helper methods for Arabic text handling
  def arabic_text?(text)
    return false if text.blank?
    # Check if text contains Arabic characters (Unicode range U+0600-U+06FF)
    text.match?(/[\u0600-\u06FF]/)
  end

  def get_font_family_for_text(text)
    if arabic_text?(text)
      "Noto Sans Arabic"
    else
      "Arial"
    end
  end
end
