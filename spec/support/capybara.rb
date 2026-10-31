require "capybara/rspec"
require "capybara-playwright-driver"

Capybara.default_driver = :rack_test

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # `driven_by` re-registers the :playwright driver from these options, so they
  # must be passed here; a separate Capybara.register_driver(:playwright) would
  # be overwritten. The CLI is pinned to the version playwright-ruby-client
  # declares, the same one CI installs browsers with.
  config.before(:each, type: :system, js: true) do
    driven_by :playwright, options: {
      browser_type: :chromium,
      playwright_cli_executable_path: "npx --yes playwright@#{Playwright::COMPATIBLE_PLAYWRIGHT_VERSION}",
      headless: ENV.fetch("HEADLESS", "true") == "true"
    }
  end
end
