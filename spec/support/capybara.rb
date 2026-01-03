require "capybara/rspec"
require "capybara-playwright-driver"

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :playwright

Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: ENV.fetch("HEADLESS", "true") == "true"
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :playwright
  end
end
