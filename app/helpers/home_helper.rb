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

  # Curated [base, glow1, glow2] color triples for placeholder artwork.
  # Composed as a layered "mesh" gradient: a saturated base with two brighter
  # radial glows. Vivid on purpose; reads well under a white icon and the dark
  # bottom text overlay. Temporary until AI-generated cover images land.
  GRADIENTS = [
    [ "#0d9488", "#2dd4bf", "#0891b2" ], # teal · turquoise · cyan
    [ "#4f46e5", "#a855f7", "#ec4899" ], # indigo · violet · pink
    [ "#ea580c", "#f59e0b", "#e11d48" ], # orange · amber · rose
    [ "#16a34a", "#84cc16", "#0d9488" ], # green · lime · teal
    [ "#db2777", "#a855f7", "#6366f1" ], # rose · purple · indigo
    [ "#0284c7", "#38bdf8", "#6366f1" ], # sky · blue · indigo
    [ "#d97706", "#f43f5e", "#f59e0b" ], # amber · rose · gold
    [ "#7c3aed", "#6366f1", "#3b82f6" ], # violet · indigo · blue
    [ "#e11d48", "#ec4899", "#a855f7" ], # crimson · pink · purple
    [ "#059669", "#10b981", "#0ea5e9" ]  # emerald · green · sky
  ].freeze

  # Deterministic mesh gradient for a hit: same item always renders the same
  # gradient (String#sum is stable across processes, unlike String#hash).
  def home_gradient(hit)
    seed = "#{hit.try(:id)}#{hit.try(:title)}".sum
    base, glow1, glow2 = GRADIENTS[seed % GRADIENTS.size]
    x1 = 12 + seed % 30
    x2 = 70 + seed % 22
    "background-color: #{base};" \
      "background-image: radial-gradient(at #{x1}% 18%, #{glow1} 0, transparent 55%)," \
      "radial-gradient(at #{x2}% 8%, #{glow2} 0, transparent 50%)," \
      "radial-gradient(at 50% 105%, #{glow1} 0, transparent 60%);"
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
