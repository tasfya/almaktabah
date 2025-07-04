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
      # Copy files to temp location
      mp3_path = copy_file_to_temp(audio_file, "audio.mp3")
      logo_path = copy_file_to_temp(logo_file, "logo.png")

      # Create background image with text
      background_path = create_background_image(logo_path, temp_dir.join("background.png"))

      # Generate video
      output_path = temp_dir.join("output.mp4")
      generate_video(mp3_path, background_path, output_path)

      # Return the generated video file
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
    create_background_with_pango(logo_path, output_path)
  end

  def create_background_with_pango(logo_path, output_path)
    require "cairo"
    require "pango"

    # Create Cairo surface
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_RGB24, 1920, 1080)
    context = Cairo::Context.new(surface)

    # Set dark background
    context.set_source_rgb(0.1, 0.1, 0.1)  # #1a1a1a
    context.paint

    # Add logo
    add_logo_to_context(context, logo_path)

    # Add title text
    add_title_text(context, title)

    # Add description text
    add_description_text(context, description) if description.present?

    # Save to file
    surface.write_to_png(output_path.to_s)
    surface.finish

    output_path.to_s
  rescue => e
    Rails.logger.error "Pango rendering failed: #{e.message}"
    # Fallback to ImageMagick if Pango fails
    create_background_with_imagemagick(logo_path, output_path)
  end

  def add_logo_to_context(context, logo_path)
    # Load and add logo using Cairo
    logo_surface = Cairo::ImageSurface.from_png(logo_path)

    # Calculate scaling to fit 400x400 max size
    logo_width = logo_surface.width
    logo_height = logo_surface.height
    max_size = 1400

    scale = [ max_size.to_f / logo_width, max_size.to_f / logo_height ].min
    scaled_width = (logo_width * scale).to_i
    scaled_height = (logo_height * scale).to_i

    # Position logo (centered, higher up)
    x = (1920 - scaled_width) / 2
    y = 180  # Higher position

    context.save
    context.translate(x, y)
    context.scale(scale, scale)
    context.set_source(logo_surface, 0, 0)
    context.paint
    context.restore
  rescue => e
    Rails.logger.warn "Logo loading failed: #{e.message}"
    # Continue without logo
  end

  def add_title_text(context, text)
    context.save

    # Create Pango layout
    layout = context.create_pango_layout

    # Set font
    font_desc = Pango::FontDescription.new
    font_desc.family = get_font_family_for_text(text)
    font_desc.size = 40 * Pango::SCALE
    font_desc.weight = Pango::Weight::BOLD
    layout.font_description = font_desc

    # Set text and width
    layout.text = text
    layout.width = 1800 * Pango::SCALE  # Max width
    layout.alignment = Pango::Alignment::CENTER

    # Handle Arabic text direction
    if arabic_text?(text)
      layout.auto_dir = true
      # Pango automatically handles RTL text direction
    end

    # Calculate position
    text_width, text_height = layout.pixel_size
    x = (1920 - text_width) / 2
    y = 590  # Position below logo

    # Set color and draw
    context.set_source_rgb(1, 1, 1)  # White
    context.move_to(x, y)
    context.show_pango_layout(layout)

    context.restore
  end

  def add_description_text(context, text)
    context.save

    # Create Pango layout
    layout = context.create_pango_layout

    # Set font
    font_desc = Pango::FontDescription.new
    font_desc.family = get_font_family_for_text(text)
    font_desc.size = 28 * Pango::SCALE
    font_desc.weight = Pango::Weight::NORMAL
    layout.font_description = font_desc

    # Set text and width
    layout.text = text
    layout.width = 1700 * Pango::SCALE  # Max width
    layout.alignment = Pango::Alignment::CENTER

    # Handle Arabic text direction
    if arabic_text?(text)
      layout.auto_dir = true
    end

    # Calculate position
    text_width, text_height = layout.pixel_size
    x = (1920 - text_width) / 2
    y = 740  # Position below title

    # Set color and draw
    context.set_source_rgb(0.8, 0.8, 0.8)  # Light gray #cccccc
    context.move_to(x, y)
    context.show_pango_layout(layout)

    context.restore
  end

  # Fallback method using ImageMagick
  def create_background_with_imagemagick(logo_path, output_path)
    require "mini_magick"

    MiniMagick::Tool::Convert.new do |convert|
      convert << "-size" << "1920x1080"
      convert << "canvas:#1a1a1a"  # Dark background

      # Add logo (resize to fit, positioned higher)
      convert << "("
      convert << logo_path
      convert << "-resize" << "400x400>"  # Smaller logo
      convert << "-gravity" << "center"
      convert << "-geometry" << "+0-300"  # Move logo higher up
      convert << ")"
      convert << "-composite"

      # Add title with better spacing and size
      convert << "-font" << get_font_for_text(title)
      convert << "-fill" << "white"
      convert << "-pointsize" << "60"  # Smaller font size
      convert << "-gravity" << "center"
      convert << "-size" << "1800x"  # Set width constraint for text wrapping
      convert << "-annotate" << "+0+50" << word_wrap(title, 50)

      # Add description with better positioning
      if description.present?
        convert << "-font" << get_font_for_text(description)
        convert << "-fill" << "#cccccc"
        convert << "-pointsize" << "28"  # Smaller description font
        convert << "-gravity" << "center"
        convert << "-size" << "1700x"  # Width constraint for description
        convert << "-annotate" << "+0+200" << word_wrap(description, 80)
      end

      convert << output_path.to_s
    end

    output_path.to_s
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
    words = text.split(" ")
    lines = []
    current_line = []

    words.each do |word|
      # Check if adding this word would exceed the line length
      test_line = (current_line + [ word ]).join(" ")
      if test_line.length <= max_chars
        current_line << word
      else
        # Start a new line
        lines << current_line.join(" ") unless current_line.empty?
        current_line = [ word ]
      end
    end

    # Add the last line
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
      "Noto Sans Arabic"  # This is widely available and has excellent Arabic support
    else
      "Arial"
    end
  end
end
