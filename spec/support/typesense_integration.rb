# frozen_string_literal: true

# Support for real-Typesense integration specs (tagged `:typesense`).
#
# Unlike the mocked service specs, these index real records into a running
# Typesense instance and exercise the query path end to end, closing the gap
# between "what our models index" and "what the listing services read back".
#
# Safety: the search services query hardcoded collection names ("Book", ...),
# the same names your local dev instance uses. To avoid wiping local dev data,
# these specs are opt-in outside CI: set RUN_TYPESENSE_SPECS=1 and point
# TYPESENSE_PORT at a disposable instance. In CI they always run.
module TypesenseIntegration
  MODELS = [ Book, Article, Lecture, Series, Fatwa, News ].freeze

  module_function

  def enabled?
    ENV["CI"].present? || ENV["RUN_TYPESENSE_SPECS"].present?
  end

  def reachable?
    TypesenseSearch::Client.instance.health.retrieve["ok"]
  rescue StandardError
    false
  end

  def endpoint
    "#{ENV.fetch('TYPESENSE_HOST', 'localhost')}:#{ENV.fetch('TYPESENSE_PORT', '8108')}"
  end

  # Delete every collection on the configured instance and drop the gem's
  # per-model collection cache, so each example starts from an empty index.
  def reset!
    client = TypesenseSearch::Client.instance
    Array(client.collections.retrieve).each do |collection|
      client.collections[collection["name"]].delete
    rescue Typesense::Error
      nil
    end
    MODELS.each { |model| model.instance_variable_set(:@typesense_indexes, {}) }
  end

  # The app's 2s request timeout suits page requests, but this harness deletes
  # and recreates six collections around every example, and on a busy machine
  # those calls can take longer. The client then retries the timed-out request:
  # a retried create fails with ObjectAlreadyExists although the first one
  # succeeded. Give the test client more time and no retries, so a slow call
  # waits and a real failure surfaces as itself. The models keep the client they
  # were loaded with, so each gets the new one.
  def configure_client!
    Typesense.configuration = Typesense.configuration.merge(connection_timeout_seconds: 10, num_retries: 0)
    TypesenseSearch::Client.reset!
    MODELS.each { |model| model.typesense_client = Typesense.client }
  end

  # Create all six collections (empty) so multi-collection services
  # (HomeBrowseService, MixedSearchService) find every collection they query,
  # mirroring production where all collections always exist.
  def ensure_collections!
    MODELS.each { |model| model.send(:typesense_ensure_init) }
  end
end

module TypesenseIntegrationHelpers
  # Index the given records synchronously into real Typesense.
  def index_records(*records)
    records.flatten.each { |record| record.class.index!(record) }
  end

  def typesense_num_documents(collection)
    TypesenseSearch::Client.instance.collections[collection].retrieve["num_documents"]
  end
end

RSpec.configure do |config|
  config.include TypesenseIntegrationHelpers, :typesense

  config.before(:suite) { TypesenseIntegration.configure_client! if TypesenseIntegration.enabled? }

  config.before(:each, :typesense) do
    skip "Typesense integration specs are opt-in locally: set RUN_TYPESENSE_SPECS=1 (point TYPESENSE_PORT at a disposable instance, not your dev data)" unless TypesenseIntegration.enabled?
    skip "Typesense not reachable at #{TypesenseIntegration.endpoint}" unless TypesenseIntegration.reachable?

    TypesenseIntegration.reset!
    TypesenseIntegration.ensure_collections!
  end

  config.after(:each, :typesense) do
    TypesenseIntegration.reset! if TypesenseIntegration.enabled? && TypesenseIntegration.reachable?
  end
end
