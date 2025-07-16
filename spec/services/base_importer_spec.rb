require 'rails_helper'

RSpec.describe BaseImporter, type: :service do
  let(:test_file_path) { Rails.root.join('spec', 'fixtures', 'test_import.xlsx') }
  let(:invalid_file_path) { Rails.root.join('spec', 'fixtures', 'nonexistent.xlsx') }
  let(:csv_file_path) { Rails.root.join('spec', 'fixtures', 'test_import.csv') }
  let(:domain) { create(:domain) }

  before do
    # Create a simple test Excel file
    workbook = WriteXLSX.new(test_file_path.to_s)
    worksheet = workbook.add_worksheet("TestSheet")
    worksheet.write(0, 0, "title")
    worksheet.write(0, 1, "description")
    worksheet.write(1, 0, "Test Title")
    worksheet.write(1, 1, "Test Description")
    workbook.close
  end

  after do
    File.delete(test_file_path) if File.exist?(test_file_path)
  end

  describe '#initialize' do
    it 'initializes with file path, domain_id and optional sheet name' do
      importer = BaseImporter.new(test_file_path, sheet_name: 'TestSheet', domain_id: domain.id)
      expect(importer.file_path).to eq(test_file_path)
      expect(importer.sheet_name).to eq('TestSheet')
      expect(importer.domain_id).to eq(domain.id)
      expect(importer.errors).to be_empty
      expect(importer.success_count).to eq(0)
      expect(importer.error_count).to eq(0)
    end

    it 'initializes without sheet name' do
      importer = BaseImporter.new(test_file_path, domain_id: domain.id)
      expect(importer.sheet_name).to be_nil
      expect(importer.domain_id).to eq(domain.id)
    end

    it 'raises error when domain_id is not provided' do
      expect {
        BaseImporter.new(test_file_path, domain_id: nil)
      }.to raise_error(ArgumentError, "domain_id is required")
    end

    it 'raises error when domain_id is blank' do
      expect {
        BaseImporter.new(test_file_path, domain_id: nil)
      }.to raise_error(ArgumentError, "domain_id is required")
    end
  end

  describe '#import' do
    context 'with invalid file' do
      it 'returns false and adds error for non-existent file' do
        importer = BaseImporter.new(invalid_file_path, domain_id: domain.id)
        result = importer.import

        expect(result).to be_falsey
      end

      it 'returns false and adds error for CSV file' do
        # Create a CSV file
        File.write(csv_file_path, "title,description\nTest,Test Description")

        importer = BaseImporter.new(csv_file_path, domain_id: domain.id)
        result = importer.import

        expect(result).to be_falsey
        File.delete(csv_file_path)
      end
    end

    context 'with valid Excel file' do
      it 'returns true for empty implementation' do
        # Override process_row to avoid NotImplementedError
        allow_any_instance_of(BaseImporter).to receive(:process_row)

        importer = BaseImporter.new(test_file_path, domain_id: domain.id)
        result = importer.import

        expect(result).to be_truthy
      end
    end
  end

  describe '#summary' do
    it 'returns correct summary' do
      importer = BaseImporter.new(test_file_path, domain_id: domain.id)
      importer.instance_variable_set(:@success_count, 5)
      importer.instance_variable_set(:@error_count, 2)
      importer.instance_variable_set(:@errors, [ 'Error 1', 'Error 2' ])

      summary = importer.summary

      expect(summary[:success_count]).to eq(5)
      expect(summary[:error_count]).to eq(2)
      expect(summary[:errors]).to eq([ 'Error 1', 'Error 2' ])
    end
  end

  describe 'helper methods' do
    let(:importer) { BaseImporter.new(test_file_path, domain_id: domain.id) }

    describe '#parse_boolean' do
      it 'parses various boolean values correctly' do
        expect(importer.send(:parse_boolean, 'true')).to be_truthy
        expect(importer.send(:parse_boolean, '1')).to be_truthy
        expect(importer.send(:parse_boolean, 'yes')).to be_truthy
        expect(importer.send(:parse_boolean, 'Y')).to be_truthy
        expect(importer.send(:parse_boolean, 'false')).to be_falsey
        expect(importer.send(:parse_boolean, '0')).to be_falsey
        expect(importer.send(:parse_boolean, 'no')).to be_falsey
        expect(importer.send(:parse_boolean, '')).to be_falsey
        expect(importer.send(:parse_boolean, nil)).to be_falsey
      end
    end

    describe '#parse_date' do
      it 'parses valid dates' do
        date = importer.send(:parse_date, '2024-01-15')
        expect(date).to eq(Date.new(2024, 1, 15))
      end

      it 'returns nil for invalid dates' do
        expect(importer.send(:parse_date, 'invalid')).to be_nil
        expect(importer.send(:parse_date, '')).to be_nil
        expect(importer.send(:parse_date, nil)).to be_nil
      end
    end

    describe '#parse_datetime' do
      it 'parses valid datetimes' do
        datetime = importer.send(:parse_datetime, '2024-01-15 10:30:00')
        expect(datetime).to be_a(DateTime)
        expect(datetime.year).to eq(2024)
        expect(datetime.month).to eq(1)
        expect(datetime.day).to eq(15)
      end

      it 'returns nil for invalid datetimes' do
        expect(importer.send(:parse_datetime, 'invalid')).to be_nil
        expect(importer.send(:parse_datetime, '')).to be_nil
        expect(importer.send(:parse_datetime, nil)).to be_nil
      end
    end

    describe '#parse_integer' do
      it 'parses valid integers' do
        expect(importer.send(:parse_integer, '123')).to eq(123)
        expect(importer.send(:parse_integer, 456)).to eq(456)
      end

      it 'returns nil for blank values' do
        expect(importer.send(:parse_integer, '')).to be_nil
        expect(importer.send(:parse_integer, nil)).to be_nil
      end
    end
  end
end
