require 'rails_helper'

RSpec.describe ExcelTemplateGenerator, type: :service do
  let(:templates_dir) { Rails.root.join('data', 'excel_templates') }
  let(:template_path) { templates_dir.join('almaktabah_import_template.xlsx') }

  after do
    File.delete(template_path) if File.exist?(template_path)
  end

  describe '.generate_unified_template' do
    it 'generates unified Excel template' do
      expect {
        ExcelTemplateGenerator.generate_unified_template
      }.to output(/Unified Excel template generated/).to_stdout

      expect(File.exist?(template_path)).to be_truthy
    end

    it 'creates template with all required sheets' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      sheets = spreadsheet.sheets

      expect(sheets).to include("Books")
      expect(sheets).to include("Lectures")
      expect(sheets).to include("Lessons")
      expect(sheets).to include("Benefits")
      expect(sheets).to include("Fatwas")
    end

    it 'creates Books sheet with correct headers' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      spreadsheet.default_sheet = "Books"

      headers = spreadsheet.row(1)
      expected_headers =  [ "title", "description", "category", "author_first_name", "author_last_name", "pages", "file_url", "cover_image_url", "published_at" ]
      expect(headers).to eq(expected_headers)
    end

    it 'creates Lectures sheet with correct headers' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      spreadsheet.default_sheet = "Lectures"

      headers = spreadsheet.row(1)
      expected_headers = [ "title", "description", "category", "youtube_url", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

      expect(headers).to eq(expected_headers)
    end

    it 'creates Lessons sheet with correct headers' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      spreadsheet.default_sheet = "Lessons"

      headers = spreadsheet.row(1)
      expected_headers = [ "title", "description", "category", "series_title", "youtube_url", "position", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

      expect(headers).to eq(expected_headers)
    end

    it 'creates Benefits sheet with correct headers' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      spreadsheet.default_sheet = "Benefits"

      headers = spreadsheet.row(1)
      expected_headers = [ "title", "description", "category", "thumbnail_url", "audio_file_url", "video_file_url", "published_at" ]

      expect(headers).to eq(expected_headers)
    end

    it 'creates Fatwas sheet with correct headers' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)
      spreadsheet.default_sheet = "Fatwas"

      headers = spreadsheet.row(1)
      expected_headers = [ "title", "category", "question", "answer", "published_at" ]

      expect(headers).to eq(expected_headers)
    end

    it 'creates headers-only template (no sample data)' do
      ExcelTemplateGenerator.generate_unified_template

      spreadsheet = Roo::Excelx.new(template_path)

      %w[Books Lectures Lessons Benefits Fatwas].each do |sheet_name|
        spreadsheet.default_sheet = sheet_name
        expect(spreadsheet.last_row).to eq(1)
      end
    end
  end
end
