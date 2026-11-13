# Avo shows a field's help only on forms, so a warning has to carry its own
# consequence and be styled to stand out on index and show pages.
module Avo::WarningMarkup
  extend ActionView::Helpers::TagHelper

  def self.alert(text)
    content_tag(:div, "⚠ #{text}", class: "rounded-md border border-red-300 bg-red-50 px-3 py-2 font-semibold text-red-700")
  end

  def self.badge(text, title:)
    content_tag(:span, text, title: title, class: "inline-block whitespace-nowrap rounded-md bg-red-500 px-2 py-1 text-xs font-bold text-white")
  end
end
