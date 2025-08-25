module FaviconHelper
  def favicon_ico_url
    return url_for(@domain.favicon_ico) if @domain&.favicon_ico&.present?
    nil
  end

  def favicon_png_url
    return url_for(@domain.favicon_png) if @domain&.favicon_png&.present?
    nil
  end

  def favicon_svg_url
    return url_for(@domain.favicon_svg) if @domain&.favicon_svg&.present?
    nil
  end

  def apple_touch_icon_url
    return url_for(@domain.apple_touch_icon) if @domain&.apple_touch_icon&.present?
    nil
  end

  def favicon_link_tags
    content_tag_string = ""

    content_tag_string += tag.link(rel: "icon", href: favicon_ico_url, type: "image/x-icon")
    content_tag_string += tag.link(rel: "icon", href: favicon_png_url, type: "image/png")
    content_tag_string += tag.link(rel: "icon", href: favicon_svg_url, type: "image/svg+xml")

    # Apple touch icon for iOS (critical for iPhone lock screen display)
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "180x180")

    # Additional iOS optimizations for lock screen display
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "152x152")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "144x144")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "120x120")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "114x114")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "76x76")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "72x72")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "60x60")
    content_tag_string += tag.link(rel: "apple-touch-icon", href: apple_touch_icon_url, sizes: "57x57")

    # Android Chrome icons
    content_tag_string += tag.link(rel: "icon", href: favicon_png_url, sizes: "192x192", type: "image/png")
    content_tag_string += tag.link(rel: "icon", href: favicon_png_url, sizes: "32x32", type: "image/png")
    content_tag_string += tag.link(rel: "icon", href: favicon_png_url, sizes: "16x16", type: "image/png")

    # Web app manifest support for PWA
    content_tag_string += tag.meta(name: "apple-mobile-web-app-capable", content: "yes")
    content_tag_string += tag.meta(name: "apple-mobile-web-app-status-bar-style", content: "default")
    content_tag_string += tag.meta(name: "apple-mobile-web-app-title", content: site_info[:name])

    content_tag_string.html_safe
  end
end
