Typesense.configuration = {
  nodes: [ {
    host: ENV.fetch("TYPESENSE_HOST", "localhost"),
    port: ENV.fetch("TYPESENSE_PORT", "8108"),
    protocol: "http"
  } ],
  api_key: ENV.fetch("TYPESENSE_API_KEY", "dev_api_key_almaktabah_2024"),
  connection_timeout_seconds: 2,
  log_level: :info,
  pagination_backend: :pagy
}
