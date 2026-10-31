require "rails_helper"
require "open3"

# Development loads routes lazily, and that lazy load is not thread-safe:
# SolidQueue's worker threads inside Puma raced on it and failed with
# NoMethodError on route helpers. Development must boot with routes loaded.
RSpec.describe "config/environments/development.rb" do
  it "loads routes during boot" do
    output, status = Open3.capture2e(
      { "RAILS_ENV" => "development" },
      "bin/rails", "runner", "print Rails.application.routes_reloader.loaded",
      chdir: Rails.root.to_s
    )

    expect(status).to be_success, output
    expect(output.lines.last).to eq("true")
  end
end
