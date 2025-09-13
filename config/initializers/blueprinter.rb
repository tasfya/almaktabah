# frozen_string_literal: true

Blueprinter.configure do |config|
  # ActiveRecord preloader for associations
  config.extensions << BlueprinterActiveRecord::Preloader.new(auto: true)
  # Keep fields in definition order for deterministic payloads
  config.sort_fields_by = :definition
  # ISO8601 formatting for time-like fields when used with datetime_format
  config.datetime_format = ->(dt) { dt&.iso8601 }
end
