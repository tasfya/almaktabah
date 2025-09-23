class ThemePlaygroundController < ApplicationController
  before_action :ensure_development

  def index
  end

  private

  def ensure_development
    unless Rails.env.development?
      redirect_to root_path, alert: "This page is only available in development mode."
    end
  end
end
