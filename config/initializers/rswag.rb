Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.join("swagger").to_s
end

Rswag::Ui.configure do |c|
  c.swagger_endpoint "/api-docs/v1/swagger.json", "API V1 Docs"
end
