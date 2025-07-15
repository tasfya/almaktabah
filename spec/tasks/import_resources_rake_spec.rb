require 'rails_helper'
require 'rake'

RSpec.describe 'import_resources rake tasks' do
  before(:all) do
    Rake.application.rake_require('tasks/import_resources')
    Rake::Task.define_task(:environment)
  end

  let(:file_path) { 'spec/fixtures/test_import.xlsx' }

  shared_examples "an importer task" do |task_name, importer_class, default_sheet|
    let(:task) { Rake::Task[task_name] }
    let(:sheet_name) { "#{default_sheet}" }
    let(:mock_importer) { instance_double(importer_class) }

    before do
      allow(importer_class.constantize).to receive(:new).with(file_path, sheet_name).and_return(mock_importer)
      allow(mock_importer).to receive(:import)
      allow(mock_importer).to receive(:import_summary).and_return({
        success_count: 2,
        error_count: 1,
        errors: [ "Row 3: Invalid format" ]
      })
    end

    after { task.reenable }

    it "runs #{task_name} with mocked #{importer_class}" do
      expect {
        task.invoke(file_path, sheet_name)
      }.to output(/Import completed!/).to_stdout

      expect(importer_class.constantize).to have_received(:new).with(file_path, sheet_name)
      expect(mock_importer).to have_received(:import)
      expect(mock_importer).to have_received(:import_summary)
    end
  end

  describe 'import_resources:books' do
    it_behaves_like "an importer task", 'import_resources:books', 'BooksImporter', 'Books'
  end

  describe 'import_resources:lectures' do
    it_behaves_like "an importer task", 'import_resources:lectures', 'LecturesImporter', 'Lectures'
  end

  describe 'import_resources:lessons' do
    it_behaves_like "an importer task", 'import_resources:lessons', 'LessonsImporter', 'Lessons'
  end

  describe 'import_resources:benefits' do
    it_behaves_like "an importer task", 'import_resources:benefits', 'BenefitsImporter', 'Benefits'
  end

  describe 'import_resources:fatwas' do
    it_behaves_like "an importer task", 'import_resources:fatwas', 'FatwasImporter', 'Fatwas'
  end

  describe 'import_resources:all' do
    let(:task) { Rake::Task['import_resources:all'] }
    let(:mock_importer) { instance_double('UnifiedImporter') }

    before do
      allow(UnifiedImporter).to receive(:new).with(file_path).and_return(mock_importer)
      allow(mock_importer).to receive(:import_all)
      allow(mock_importer).to receive(:print_summary)
    end

    after { task.reenable }

    it 'runs unified importer and prints summary' do
      expect {
        task.invoke(file_path)
      }.to output(/Starting unified import/).to_stdout

      expect(UnifiedImporter).to have_received(:new).with(file_path)
      expect(mock_importer).to have_received(:import_all)
      expect(mock_importer).to have_received(:print_summary)
    end
  end

  describe 'import_resources:generate_template' do
    let(:task) { Rake::Task['import_resources:generate_template'] }

    before do
      allow(ExcelTemplateGenerator).to receive(:generate_unified_template)
    end

    after { task.reenable }

    it 'generates the Excel template' do
      expect {
        task.invoke
      }.to output(/Generating unified Excel template/).to_stdout

      expect(ExcelTemplateGenerator).to have_received(:generate_unified_template)
    end
  end

  describe 'import_resources:info' do
    let(:task) { Rake::Task['import_resources:info'] }

    after { task.reenable }

    it 'displays the import info text' do
      expect {
        task.invoke
      }.to output(/Excel Import System Information:/).to_stdout
    end
  end
end
