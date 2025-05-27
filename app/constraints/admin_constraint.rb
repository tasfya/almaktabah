class AdminConstraint
  def matches?(request)
    return false unless request.session[:warden.user.user.key].present?
    user_id = request.session[:warden.user.user.key].flatten.first
    user = User.find_by(id: user_id)
    user&.admin?
  end
end
