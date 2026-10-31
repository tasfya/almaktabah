# frozen_string_literal: true

# Compares output with a committed file under spec/fixtures/golden, to pin
# current behavior before a refactor. Regenerate after an intended change with
#
#   UPDATE_GOLDEN=1 bin/worktree test spec/path/to_spec.rb
#
# and review the diff of the golden file in the PR. Strip values that change
# between runs (ids, timestamps, Faker data, asset digests) with a normalizer:
#
#   expect(response).to match_golden("sitemaps/static.xml")
#   expect(response).to match_golden("pages/book.html").normalized_by { |s| s.gsub(/\d{4}-\d\d-\d\d/, "DATE") }
module GoldenFiles
  ROOT = Rails.root.join("spec/fixtures/golden")

  def self.update?
    ENV["UPDATE_GOLDEN"].present?
  end
end

RSpec::Matchers.define :match_golden do |name|
  chain(:normalized_by) { |&block| @normalizer = block }

  match do |actual|
    @path = GoldenFiles::ROOT.join(name)
    @output = MarkupHelpers.markup_of(actual)
    @output = @normalizer.call(@output) if @normalizer

    if GoldenFiles.update?
      FileUtils.mkdir_p(@path.dirname)
      File.write(@path, @output)
    end

    @path.exist? && File.read(@path) == @output
  end

  failure_message do
    relative = @path.relative_path_from(Rails.root)
    if @path.exist?
      "output differs from #{relative} (rerun with UPDATE_GOLDEN=1 if the change is intended):" +
        RSpec::Support::Differ.new(color: RSpec::Matchers.configuration.color?).diff(@output, File.read(@path))
    else
      "no golden file at #{relative}; run with UPDATE_GOLDEN=1 to create it"
    end
  end
end
