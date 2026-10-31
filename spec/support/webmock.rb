# frozen_string_literal: true

require "webmock/rspec"

# Specs never reach the internet. Localhost stays open for the services the
# suite really talks to: Typesense and the Capybara app server driven by
# Playwright.
WebMock.disable_net_connect!(allow_localhost: true)
