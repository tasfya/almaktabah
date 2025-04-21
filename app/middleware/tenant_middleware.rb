class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    subdomain = extract_subdomain(request)
    tenant = Tenant.find_by!(subdomain: subdomain)
    Current.tenant = tenant

    @app.call(env)
  ensure
    raise "Tenant not found" if Current.tenant.nil?
  end

  private

  def extract_subdomain(request)
    host = request.host
    return nil if host.split(".").length <= 2
    host.split(".").first # Notice: improve extaction of the subdomain
  end
end
