require "roo"
require "write_xlsx"

class ExcelTemplateGenerator
  def self.generate_unified_template
    new.generate_unified_template
  end

  def initialize
    @templates_dir = Rails.root.join("data", "excel_templates")
    FileUtils.mkdir_p(@templates_dir)
  end

  def generate_unified_template
    file_path = @templates_dir.join("almaktabah_import_template.xlsx")

    workbook = WriteXLSX.new(file_path.to_s)

    create_books_worksheet(workbook)
    create_lectures_worksheet(workbook)
    create_lessons_worksheet(workbook)
    create_benefits_worksheet(workbook)
    create_fatwas_worksheet(workbook)

    workbook.close
    puts "Unified Excel template generated: #{file_path}"
  end

  private

  def create_books_worksheet(workbook)
    worksheet = workbook.add_worksheet("Books")

    headers = [ "title", "description", "category", "author_first_name", "author_last_name", "pages", "file_url", "cover_image_url", "published_at" ]

    headers.each_with_index do |header, index|
      worksheet.write(0, index, header)
    end
  end

  def create_lectures_worksheet(workbook)
    worksheet = workbook.add_worksheet("Lectures")

    headers = [ "title", "description", "category", "youtube_url", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

    headers.each_with_index do |header, index|
      worksheet.write(0, index, header)
    end
  end

  def create_lessons_worksheet(workbook)
    worksheet = workbook.add_worksheet("Lessons")

    headers = [ "title", "description", "category", "series_title", "youtube_url", "position", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

    headers.each_with_index do |header, index|
      worksheet.write(0, index, header)
    end
  end

  def create_benefits_worksheet(workbook)
    worksheet = workbook.add_worksheet("Benefits")

    headers = [ "title", "description", "category", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

    headers.each_with_index do |header, index|
      worksheet.write(0, index, header)
    end
  end

  def create_fatwas_worksheet(workbook)
    worksheet = workbook.add_worksheet("Fatwas")

    headers = [ "title", "category", "question", "answer", "published_at" ]

    headers.each_with_index do |header, index|
      worksheet.write(0, index, header)
    end
  end
end
