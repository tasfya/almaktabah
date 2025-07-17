require 'rails_helper'
require 'rake'

RSpec.describe 'Import Resources Rake Tasks', type: :task do
  let(:domain) { create(:domain) }
  let(:csv_path) { Rails.root.join('data', 'csv_templates', 'books.csv') }
  let(:processor_mock) { instance_double(CsvImportProcessor) }

  before do
    Rake.application.rake_require 'tasks/import_resources'
    Rake::Task.define_task(:environment)
  end

  describe 'import_resources:books' do
    let(:task) { Rake::Task['import_resources:books'] }

    before do
      task.reenable
    end

    it 'calls CsvImportProcessor with correct parameters' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'BooksImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(true)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 5,
        skipped_count: 1,
        error_count: 0,
        errors: []
      })

      task.invoke(csv_path.to_s, domain.id.to_s)
    end

    it 'raises error if DOMAIN_ID is not provided' do
      expect { task.invoke }.to raise_error(SystemExit)
    end

    it 'handles processing errors gracefully' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'BooksImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(false)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 0,
        skipped_count: 0,
        error_count: 1,
        errors: [ { line: 2, message: "Processing failed" } ]
      })

      ENV['DOMAIN_ID'] = domain.id.to_s

      expect { task.invoke }.to output(/Processing failed with errors/).to_stdout

      ENV.delete('DOMAIN_ID')
    end
  end

  describe 'import_resources:lectures' do
    let(:task) { Rake::Task['import_resources:lectures'] }
    let(:csv_path) { Rails.root.join('data', 'csv_templates', 'lectures.csv') }

    before do
      task.reenable
    end

    it 'calls CsvImportProcessor with correct parameters' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'LecturesImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(true)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 3,
        skipped_count: 0,
        error_count: 0,
        errors: []
      })

      ENV['DOMAIN_ID'] = domain.id.to_s
      task.invoke
      ENV.delete('DOMAIN_ID')
    end
  end

  describe 'import_resources:lessons' do
    let(:task) { Rake::Task['import_resources:lessons'] }
    let(:csv_path) { Rails.root.join('data', 'csv_templates', 'lessons.csv') }

    before do
      task.reenable
    end

    it 'calls CsvImportProcessor with correct parameters' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'LessonsImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(true)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 10,
        skipped_count: 2,
        error_count: 0,
        errors: []
      })

      ENV['DOMAIN_ID'] = domain.id.to_s
      task.invoke
      ENV.delete('DOMAIN_ID')
    end
  end

  describe 'import_resources:benefits' do
    let(:task) { Rake::Task['import_resources:benefits'] }
    let(:csv_path) { Rails.root.join('data', 'csv_templates', 'benefits.csv') }

    before do
      task.reenable
    end

    it 'calls CsvImportProcessor with correct parameters' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'BenefitsImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(true)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 8,
        skipped_count: 1,
        error_count: 0,
        errors: []
      })

      ENV['DOMAIN_ID'] = domain.id.to_s
      task.invoke
      ENV.delete('DOMAIN_ID')
    end
  end

  describe 'import_resources:fatwas' do
    let(:task) { Rake::Task['import_resources:fatwas'] }
    let(:csv_path) { Rails.root.join('data', 'csv_templates', 'fatwas.csv') }

    before do
      task.reenable
    end

    it 'calls CsvImportProcessor with correct parameters' do
      expect(CsvImportProcessor).to receive(:new)
        .with(csv_path.to_s, 'FatwasImportJob', domain.id)
        .and_return(processor_mock)
      expect(processor_mock).to receive(:process).and_return(true)
      expect(processor_mock).to receive(:summary).and_return({
        enqueued_count: 6,
        skipped_count: 0,
        error_count: 0,
        errors: []
      })

      ENV['DOMAIN_ID'] = domain.id.to_s
      task.invoke
      ENV.delete('DOMAIN_ID')
    end
  end

  describe 'output formatting' do
    let(:task) { Rake::Task['import_resources:books'] }

    before do
      task.reenable
      allow(CsvImportProcessor).to receive(:new).and_return(processor_mock)
      allow(processor_mock).to receive(:process).and_return(true)
    end

    it 'displays success summary correctly' do
      allow(processor_mock).to receive(:summary).and_return({
        enqueued_count: 10,
        skipped_count: 2,
        error_count: 0,
        errors: []
      })

      ENV['DOMAIN_ID'] = domain.id.to_s

      expect { task.invoke }.to output(/Import completed successfully!/).to_stdout
      expect { task.invoke }.to output(/Enqueued: 10 jobs/).to_stdout
      expect { task.invoke }.to output(/Skipped: 2 rows/).to_stdout

      ENV.delete('DOMAIN_ID')
    end

    it 'displays error summary correctly' do
      allow(processor_mock).to receive(:process).and_return(true)
      allow(processor_mock).to receive(:summary).and_return({
        enqueued_count: 8,
        skipped_count: 1,
        error_count: 2,
        errors: [
          { line: 3, message: "Invalid data format" },
          { line: 7, message: "Missing required field" }
        ]
      })

      ENV['DOMAIN_ID'] = domain.id.to_s

      expect { task.invoke }.to output(/Import completed with some errors/).to_stdout
      expect { task.invoke }.to output(/Line 3: Invalid data format/).to_stdout
      expect { task.invoke }.to output(/Line 7: Missing required field/).to_stdout

      ENV.delete('DOMAIN_ID')
    end
  end
end
