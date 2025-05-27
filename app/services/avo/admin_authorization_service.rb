class Avo::AdminAuthorizationService
  attr_reader :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def authorize(access_level, model_class, record = nil)
    # Return true if user is admin, false otherwise
    current_user&.admin?
  end
end
