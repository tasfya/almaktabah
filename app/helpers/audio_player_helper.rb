module AudioPlayerHelper
  # Generate a play button for the global audio player
  def audio_play_button(audio_url, title, author = "", artwork = "", options = {})
    return unless audio_url.present?

    button_class = options[:class] || "bg-gray-800 hover:bg-gray-700 text-white p-2 rounded-lg transition-colors"
    icon_class = options[:icon_class] || "w-4 h-4"

    button_tag(
      class: button_class,
      data: {
        action: "click->audio-player#playTrack",
        audio_url: audio_url,
        audio_title: title,
        audio_author: author,
        audio_artwork: artwork
      },
      title: "#{t('actions.play')} #{title}",
      **options.except(:class, :icon_class)
    ) do
      content_tag(:svg, class: icon_class, fill: "currentColor", viewBox: "0 0 20 20") do
        content_tag(:path, "", d: "M8 5v10l8-5-8-5z")
      end
    end
  end

  # Generate a play button with text
  def audio_play_button_with_text(audio_url, title, author = "", artwork = nil, text = nil, options = {})
    return unless audio_url.present?

    artwork ||= asset_path("background.jpg")

    text ||= t("actions.listen")
    button_class = options[:class] || "flex items-center gap-2 bg-black hover:bg-gray-800 text-white px-4 py-2 rounded-lg transition-colors"

    button_tag(
      class: "flex items-center gap-1 #{button_class}",
      data: {
        action: "click->audio-player#playTrack",
        audio_url: audio_url,
        audio_title: title,
        audio_author: author,
        audio_artwork: artwork
      },
      title: "#{t('actions.play')} #{title}",
      **options.except(:class)
    ) do
      concat(
        content_tag(:svg, "", class: "w-4 h-4", fill: "currentColor", viewBox: "0 0 20 20", xmlns: "http://www.w3.org/2000/svg") do
          tag.path(d: "M8 5v10l8-5-8-5z")
        end
      )
      concat content_tag(:span, text)
    end
  end


  # Generate an inline audio player (for individual items)
  def inline_audio_player(audio_url, title, author = "", artwork = "", options = {})
    return unless audio_url.present?

    container_class = options[:class] || "flex items-center gap-3 p-3 bg-gray-50 rounded-lg"

    content_tag(:div, class: container_class) do
      concat audio_play_button(audio_url, title, author, artwork, class: "flex-shrink-0")
      concat content_tag(:div, class: "flex-1 min-w-0") do
        concat content_tag(:h4, title, class: "font-semibold text-gray-900 truncate text-sm")
        concat content_tag(:p, author, class: "text-xs text-gray-600 truncate") if author.present?
      end
    end
  end
end
