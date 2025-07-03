module AudioPlayerHelper
  def play_button(resource:, path:, klass: "btn btn-secondary w-fit", icon_class: "size-4")
    return unless resource&.audio? && path.present?
    tag.form(
      action: path,
      data: { action: "submit->application#preventDefault:reload", turbo_frame: "audio" }
    ) do
      tag.button(
        class: klass,
        data: {
          controller: "play-button",
          "play-button-player-outlet": "##{dom_id(resource, :audio)}"
        },
        type: "submit",
        data_action: "click->play-button#toggle"
      ) do
        safe_join([
          content_tag(:div, class: "block group-aria-pressed:hidden") do
            safe_join([
              content_tag(:span, "Play lesson #{resource.title}", class: "sr-only"),
              icon("play", class: "size-4")
            ])
          end,
          content_tag(:div, class: "hidden group-aria-pressed:block") do
            safe_join([
              content_tag(:span, "Pause lesson #{resource.title}", class: "sr-only"),
              icon("pause", class: "size-4")
            ])
          end,
          content_tag(:span, I18n.t("buttons.listen"), class: "ml-3", "aria-hidden": true)
        ])
      end
    end
  end
end
