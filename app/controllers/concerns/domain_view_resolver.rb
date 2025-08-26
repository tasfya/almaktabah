module DomainViewResolver
  extend ActiveSupport::Concern

  private

  def domain_template_view_exists?(template_path)
    return false unless @domain&.template_name && @domain.template_name != "default"

    template_view_path = "templates/#{@domain.template_name}/#{template_path}"
    lookup_context.template_exists?(template_view_path, [], false)
  end

  def render_with_domain_template_fallback(template, options = {})
    if @domain&.template_name && @domain.template_name != "default" && domain_template_view_exists?(template)
      template_view = "templates/#{@domain.template_name}/#{template}"
      render template_view, options
    else
      render template, options
    end
  end

  def prepend_domain_template_view_path
    return unless @domain&.template_name && @domain.template_name != "default"
    template_view_path = Rails.root.join("app", "views", "templates", @domain.template_name)
    if Dir.exist?(template_view_path)
      prepend_view_path(template_view_path)
    end
  end

  included do
    before_action :setup_domain_template_views

    private

    def setup_domain_template_views
      prepend_domain_template_view_path if @domain
    end
  end
end
