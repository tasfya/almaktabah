class ApplicationController < ActionController::Base
  before_action :set_tenant
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern


  def set_tenant
    Current.tenant = Tenant.find(session["tenant_id"])
    @title = 
    "#{Current.tenant.name} - #{Current.tenant.subdomain}"
  end
end
