class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    subdomain = extract_subdomain(request)
    Rails.logger.debug "Extracted subdomain: #{subdomain}"
    tenant = Tenant.find_by(subdomain: subdomain)
    request.session[:tenant_id] = tenant&.id
    @app.call(env)
  end

  private

  def extract_subdomain(request)
    # TODO: improve this to handle different environments and subdomain formats
    host = request.host
    return nil if host.blank?

    parts = host.split(".")
    parts.first
  end
end
