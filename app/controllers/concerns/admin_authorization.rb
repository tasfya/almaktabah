module AdminAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    authenticate_user!
    
    # Make sure there's a current user and they're an admin
    unless current_user && current_user.admin?
      respond_to do |format|
        format.html do
          flash[:alert] = "You must be an admin user to access this section"
          redirect_to root_path, status: :forbidden
        end
        format.json { render json: { error: "Access denied" }, status: :forbidden }
        format.any { head :forbidden }
      end
    end
  end
end
