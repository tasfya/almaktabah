# frozen_string_literal: true

module HomeHelper
  TYPE_ICONS = {
    "book" => "book-open",
    "lecture" => "microphone",
    "series" => "queue-list",
    "fatwa" => "scale",
    "news" => "newspaper",
    "article" => "document-text"
  }.freeze

  # Singularized content type for a SearchHit (e.g. "lecture").
  def home_type_key(hit)
    hit.content_type.to_s.singularize
  end

  def home_type_label(hit)
    key = home_type_key(hit)
    I18n.exists?("content_types.#{key}") ? t("content_types.#{key}") : key
  end

  def home_type_icon(hit)
    TYPE_ICONS[home_type_key(hit)] || "folder"
  end

  # Returns a small inline action for the sidebar/feed: label + daisyUI button
  # style. Audio content gets "listen"; books get "read"; everything else
  # falls back to a neutral "view".
  def home_action(hit)
    if hit.respond_to?(:audio_url) && hit.audio_url.present?
      { label: t("home.action.listen"), style: "btn-primary" }
    elsif home_type_key(hit) == "book"
      { label: t("home.action.read"), style: "btn-secondary" }
    else
      { label: t("home.action.view"), style: "btn-ghost" }
    end
  end
end
