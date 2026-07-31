# frozen_string_literal: true

class Avo::Tools::ApplicationController < Avo::ApplicationController
  before_action :set_pagy_locale

  private

  def set_pagy_locale
    @pagy_locale = I18n.locale.to_s
  end
end
