module BreadcrumbHelper
  def breadcrumb_for(name, path = nil, options = {})
    session[:breadcrumbs] ||= []
    session[:breadcrumbs].reject! { |crumb| crumb[:path].nil? }

    last_crumb = session[:breadcrumbs].last
    return if last_crumb&.dig(:name) == name && last_crumb&.dig(:path) == path

    breadcrumb_item = {
      name: name,
      path: path,
      created_at: Time.current
    }

    if path
      session[:breadcrumbs].reject! { |crumb| crumb[:path] == path }
    end
    session[:breadcrumbs] << breadcrumb_item
    session[:breadcrumbs] = session[:breadcrumbs].last(8) # Limit to last 8 items
  end

  def reset_breadcrumbs
    session[:breadcrumbs] = []
  end

  def current_breadcrumbs
    breadcrumbs = session[:breadcrumbs] || []
    home_breadcrumb = { name: "الصفحة الرئيسية", path: root_path }

    unless breadcrumbs.any? { |crumb| crumb[:path] == root_path }
      breadcrumbs.unshift(home_breadcrumb)
    end

    breadcrumbs
  end

  def render_breadcrumbs(options = {})
    breadcrumbs = current_breadcrumbs
    classes = options[:classes] || ""

    content_tag :div, class: "breadcrumbs text-sm #{classes}" do
      content_tag :ul do
        breadcrumbs.map.with_index do |crumb, index|
          is_last = index == breadcrumbs.length - 1
          is_current = crumb[:path].nil? || is_last

          content_tag :li do
            if is_current
              content_tag :span, crumb[:name]
            else
              link_to crumb[:name], crumb[:path]
            end
          end
        end.join.html_safe
      end
    end
  end

  def cleanup_old_breadcrumbs(max_age_hours = 24)
    return unless session[:breadcrumbs]

    cutoff_time = max_age_hours.hours.ago
    session[:breadcrumbs].reject! do |crumb|
      crumb[:created_at] && Time.parse(crumb[:created_at].to_s) < cutoff_time
    rescue ArgumentError
      true # Remove invalid timestamps
    end
  end

  def set_breadcrumb_limits(max_items = 10)
    session[:breadcrumbs] ||= []
    session[:breadcrumbs] = session[:breadcrumbs].last(max_items)
  end

  def current_page_in_breadcrumbs?(path)
    session[:breadcrumbs]&.any? { |crumb| crumb[:path] == path }
  end

  def find_breadcrumb_by_path(path)
    session[:breadcrumbs]&.find { |crumb| crumb[:path] == path }
  end

  def remove_breadcrumb(path)
    session[:breadcrumbs]&.reject! { |crumb| crumb[:path] == path }
  end

  def add_breadcrumbs(*breadcrumbs)
    breadcrumbs.each do |breadcrumb|
      if breadcrumb.is_a?(Array) && breadcrumb.length == 2
        breadcrumb_for(breadcrumb[0], breadcrumb[1])
      elsif breadcrumb.is_a?(Hash)
        breadcrumb_for(breadcrumb[:name], breadcrumb[:path], breadcrumb[:options] || {})
      end
    end
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
      "benefits" => "الفوائد",
      "search" => "البحث",
      "profile" => "الملف الشخصي",
      "bookmarks" => "المفضلة"
    }

    translations[controller] || controller.humanize
  end
end
