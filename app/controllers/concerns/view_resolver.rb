module ViewResolver
  extend ActiveSupport::Concern

  included do
    before_action :prepend_custom_template_view_path

    private

    def prepend_custom_template_view_path
      if !@domain&.template_name || @domain.template_name == "default"
        return
      end

      template_view_path = Rails.root.join("app", "views", "templates", @domain.template_name)
      if Dir.exist?(template_view_path)
        prepend_view_path(template_view_path)
      end
    end
  end
end
