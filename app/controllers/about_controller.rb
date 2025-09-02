class AboutController < ApplicationController
  before_action :setup_breadcrumbs, only: [ :index ]
  def index
  end

  private

  def setup_breadcrumbs
    breadcrumb_for(t("breadcrumbs.about"), about_path)
  end
end
