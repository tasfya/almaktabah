# Breadcrumbs live in the session and are rendered on later pages, some of
# them publicly cached. Pages that show a learner's own links or an admin-only
# title set their crumbs for the current request only, then put the session's
# crumbs back as they were.
module TransientBreadcrumbs
  extend ActiveSupport::Concern

  included do
    prepend_around_action :keep_breadcrumbs_out_of_session
  end

  private

  def keep_breadcrumbs_out_of_session
    saved = session[:breadcrumbs].deep_dup
    yield
  ensure
    session[:breadcrumbs] = saved
  end
end
