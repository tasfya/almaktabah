module BreadcrumbHelper
  # Adds a breadcrumb to the session
  def breadcrumb_for(name, path = nil, options = {})
    session[:breadcrumbs] ||= []
    # remove nil paths from the session
    session[:breadcrumbs].reject! { |crumb| crumb[:path].nil? }

    # Skip if this breadcrumb is identical to the last one
    last_crumb = session[:breadcrumbs].last
    return if last_crumb&.dig(:name) == name && last_crumb&.dig(:path) == path

    breadcrumb_item = {
      name: name,
      path: path,
      created_at: Time.current
    }

    # Remove duplicates by path
    if path
      session[:breadcrumbs].reject! { |crumb| crumb[:path] == path }
    end
    session[:breadcrumbs] << breadcrumb_item
    session[:breadcrumbs] = session[:breadcrumbs].last(8) # Limit to last 8 items
  end

  # Reset all breadcrumbs
  def reset_breadcrumbs
    session[:breadcrumbs] = []
  end

  # Returns the breadcrumbs with "Home" prepended if missing
  def current_breadcrumbs
    breadcrumbs = session[:breadcrumbs] || []
    home_breadcrumb = { name: "الصفحة الرئيسية", path: root_path }

    unless breadcrumbs.any? { |crumb| crumb[:path] == root_path }
      breadcrumbs.unshift(home_breadcrumb)
    end

    breadcrumbs
  end

  # Only renders breadcrumbs — doesn't modify session
  def render_breadcrumbs(options = {})
    breadcrumbs = current_breadcrumbs

    default_classes = {
      container: "mb-6 bg-white rounded-lg shadow-sm border border-background-contrast p-4",
      list: "flex items-center space-x-2 rtl:space-x-reverse text-sm",
      item: "flex items-center",
      link: "link",
      separator: "mx-3 text-main-text",
      current: "font-semibold"
    }

    classes = default_classes.merge(options[:classes] || {})

    content_tag :nav, class: classes[:container], "aria-label": "breadcrumb" do
      content_tag :ol, class: classes[:list] do
        breadcrumbs.map.with_index do |crumb, index|
          is_last = index == breadcrumbs.length - 1
          is_current = crumb[:path].nil? || is_last

          content_tag :li, class: classes[:item] do
            content = if is_current
              content_tag :span, crumb[:name], class: classes[:current]
            else
              link_to crumb[:name], crumb[:path], class: classes[:link]
            end

            unless is_last
              content += content_tag(:span, class: classes[:separator]) do
                content_tag(:svg, class: "w-3 h-3 rotate-180", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
                  content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M9 5l7 7-7 7")
                end
              end
            end

            content
          end
        end.join.html_safe
      end
    end
  end

  # Remove old breadcrumbs by age
  def cleanup_old_breadcrumbs(max_age_hours = 24)
    return unless session[:breadcrumbs]

    cutoff_time = max_age_hours.hours.ago
    session[:breadcrumbs].reject! do |crumb|
      crumb[:created_at] && Time.parse(crumb[:created_at].to_s) < cutoff_time
    rescue ArgumentError
      true # Remove invalid timestamps
    end
  end

  # Limit breadcrumb session size
  def set_breadcrumb_limits(max_items = 10)
    session[:breadcrumbs] ||= []
    session[:breadcrumbs] = session[:breadcrumbs].last(max_items)
  end

  # Check if a path exists in breadcrumbs
  def current_page_in_breadcrumbs?(path)
    session[:breadcrumbs]&.any? { |crumb| crumb[:path] == path }
  end

  # Find breadcrumb by path
  def find_breadcrumb_by_path(path)
    session[:breadcrumbs]&.find { |crumb| crumb[:path] == path }
  end

  # Remove breadcrumb by path
  def remove_breadcrumb(path)
    session[:breadcrumbs]&.reject! { |crumb| crumb[:path] == path }
  end

  # Add multiple breadcrumbs
  def add_breadcrumbs(*breadcrumbs)
    breadcrumbs.each do |breadcrumb|
      if breadcrumb.is_a?(Array) && breadcrumb.length == 2
        breadcrumb_for(breadcrumb[0], breadcrumb[1])
      elsif breadcrumb.is_a?(Hash)
        breadcrumb_for(breadcrumb[:name], breadcrumb[:path], breadcrumb[:options] || {})
      end
    end
  end

  # Debug breadcrumbs in development
  def debug_breadcrumbs
    return unless Rails.env.development?

    logger.debug "=== Breadcrumbs Debug ==="
    logger.debug "Session breadcrumbs: #{session[:breadcrumbs]}"
    logger.debug "Current breadcrumbs: #{current_breadcrumbs}"
    logger.debug "=========================="
  end

  private

  def translate_controller_name(controller)
    translations = {
      "home" => "الصفحة الرئيسية",
      "books" => "الكتب",
      "lectures" => "المحاضرات",
      "lessons" => "الدروس",
      "series" => "السلاسل العلمية",
      "fatwas" => "الفتاوى",
      "news" => "الأخبار",
      "search" => "البحث",
      "profile" => "الملف الشخصي",
      "bookmarks" => "المفضلة"
    }

    translations[controller] || controller.humanize
  end
end
