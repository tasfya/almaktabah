require 'rails_helper'

RSpec.describe CsvImportProcessor, type: :service do
  let(:domain) { create(:domain) }
  let(:test_csv_path) { Rails.root.join('spec', 'fixtures', 'test_import.csv') }
  let(:invalid_file_path) { Rails.root.join('spec', 'fixtures', 'nonexistent.csv') }
  let(:non_csv_path) { Rails.root.join('spec', 'fixtures', 'test_import.txt') }

  before do
    # Create a test CSV file
    CSV.open(test_csv_path, 'w') do |csv|
      csv << %w[title description category]
      csv << [ 'Book 1', 'Description 1', 'Category 1' ]
      csv << [ 'Book 2', 'Description 2', 'Category 2' ]
      csv << [ '', '', '' ] # Empty row
      csv << [ 'Book 3', 'Description 3', 'Category 3' ]
    end
  end

  after do
    File.delete(test_csv_path) if File.exist?(test_csv_path)
    File.delete(non_csv_path) if File.exist?(non_csv_path)
  end

  describe '#initialize' do
    it 'initializes with correct attributes' do
      processor = CsvImportProcessor.new(test_csv_path, 'BooksImportJob', domain.id)

      expect(processor.file_path).to eq(test_csv_path)
      expect(processor.job_class).to eq('BooksImportJob')
      expect(processor.domain_id).to eq(domain.id)
      expect(processor.enqueued_count).to eq(0)
      expect(processor.skipped_count).to eq(0)
      expect(processor.errors).to be_empty
    end
  end

  describe '#process' do
    context 'with valid CSV file' do
      it 'processes CSV and enqueues jobs' do
        processor = CsvImportProcessor.new(test_csv_path, 'BooksImportJob', domain.id)

        expect(BooksImportJob).to receive(:perform_later).exactly(3).times

        result = processor.process

        expect(result).to be_truthy
        expect(processor.enqueued_count).to eq(3)
        expect(processor.skipped_count).to eq(1) # Empty row
        expect(processor.errors).to be_empty
      end

      it 'skips empty rows' do
        processor = CsvImportProcessor.new(test_csv_path, 'BooksImportJob', domain.id)

        allow(BooksImportJob).to receive(:perform_later)

        processor.process

        expect(processor.skipped_count).to eq(1)
      end

      it 'handles job enqueue errors gracefully' do
        processor = CsvImportProcessor.new(test_csv_path, 'BooksImportJob', domain.id)

        allow(BooksImportJob).to receive(:perform_later).and_raise(StandardError.new("Job error"))

        result = processor.process

        expect(result).to be_truthy # Still returns true even with job errors
        expect(processor.enqueued_count).to eq(0)
        expect(processor.errors.size).to eq(3) # 3 non-empty rows failed
        expect(processor.errors.first[:message]).to include("Failed to enqueue job")
      end
    end

    context 'with invalid file' do
      it 'returns false for non-existent file' do
        processor = CsvImportProcessor.new(invalid_file_path, 'BooksImportJob', domain.id)

        result = processor.process

        expect(result).to be_falsey
        expect(processor.errors.first[:message]).to include("File not found")
      end

      it 'returns false for non-CSV file' do
        File.write(non_csv_path, "not a csv file")
        processor = CsvImportProcessor.new(non_csv_path, 'BooksImportJob', domain.id)

        result = processor.process

        expect(result).to be_falsey
        expect(processor.errors.first[:message]).to include("Only CSV files (.csv) are supported")
      end
    end

    context 'with malformed CSV' do
      let(:malformed_csv_path) { Rails.root.join('spec', 'fixtures', 'malformed.csv') }

      before do
        File.write(malformed_csv_path, "title,description\n\"unclosed quote")
      end

      after do
        File.delete(malformed_csv_path) if File.exist?(malformed_csv_path)
      end

      it 'handles CSV parsing errors' do
        processor = CsvImportProcessor.new(malformed_csv_path, 'BooksImportJob', domain.id)

        result = processor.process

        expect(result).to be_falsey
        expect(processor.errors.first[:message]).to include("Failed to process CSV file")
      end
    end
  end

  describe '#summary' do
    it 'returns correct summary' do
      processor = CsvImportProcessor.new(test_csv_path, 'BooksImportJob', domain.id)

      # Simulate some processing
      processor.instance_variable_set(:@enqueued_count, 5)
      processor.instance_variable_set(:@skipped_count, 2)
      processor.instance_variable_set(:@errors, [ { line: 3, message: "Test error" } ])

      summary = processor.summary

      expect(summary[:enqueued_count]).to eq(5)
      expect(summary[:skipped_count]).to eq(2)
      expect(summary[:error_count]).to eq(1)
      expect(summary[:errors]).to eq([ { line: 3, message: "Test error" } ])
    end
  end

  describe 'integration with different job classes' do
    it 'works with LecturesImportJob' do
      processor = CsvImportProcessor.new(test_csv_path, 'LecturesImportJob', domain.id)

      expect(LecturesImportJob).to receive(:perform_later).exactly(3).times

      processor.process
    end

    it 'works with LessonsImportJob' do
      processor = CsvImportProcessor.new(test_csv_path, 'LessonsImportJob', domain.id)

      expect(LessonsImportJob).to receive(:perform_later).exactly(3).times

      processor.process
    end

    it 'works with BenefitsImportJob' do
      processor = CsvImportProcessor.new(test_csv_path, 'BenefitsImportJob', domain.id)

      expect(BenefitsImportJob).to receive(:perform_later).exactly(3).times

      processor.process
    end

    it 'works with FatwasImportJob' do
      processor = CsvImportProcessor.new(test_csv_path, 'FatwasImportJob', domain.id)

      expect(FatwasImportJob).to receive(:perform_later).exactly(3).times

      processor.process
    end
  end
end
