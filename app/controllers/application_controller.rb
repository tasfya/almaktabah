class ApplicationController < ActionController::Base
  before_action :set_tenant
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern


  def set_tenant
    if session["tenant_id"]
      @current_tenant = Tenant.find(session["tenant_id"]) 
      @title = "#{@current_tenant.name} - #{@current_tenant.subdomain}"
    end
  end
end
