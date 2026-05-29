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

  # Curated [from, to] color pairs for placeholder artwork. Deep, saturated
  # tones that read well behind a white icon and the dark text overlay.
  # Temporary until AI-generated cover images land.
  GRADIENTS = [
    [ "#0f766e", "#134e4a" ], # teal
    [ "#1d4ed8", "#4c1d95" ], # blue → violet
    [ "#b45309", "#7c2d12" ], # amber → brown
    [ "#15803d", "#14532d" ], # green
    [ "#9d174d", "#581c87" ], # rose → purple
    [ "#0e7490", "#155e75" ], # cyan
    [ "#a16207", "#854d0e" ], # gold
    [ "#4338ca", "#1e3a8a" ], # indigo
    [ "#be123c", "#881337" ], # crimson
    [ "#047857", "#065f46" ]  # emerald
  ].freeze

  # Deterministic gradient for a hit: same item always renders the same
  # gradient (String#sum is stable across processes, unlike String#hash).
  def home_gradient(hit)
    seed = "#{hit.try(:id)}#{hit.try(:title)}".sum
    from, to = GRADIENTS[seed % GRADIENTS.size]
    angle = 110 + (seed * 7) % 130
    "background-image: linear-gradient(#{angle}deg, #{from}, #{to});"
  end

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
