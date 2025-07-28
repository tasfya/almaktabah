module ThemeHelper
  def custom_css_tag
    return unless @domain&.has_custom_css?

    content_tag(:style, @domain.custom_css.html_safe, type: "text/css", data: { domain: @domain.id })
  end
end
