module AudioPlayerHelper
  def play_button(resource:, klass: "btn btn-secondary w-fit whitespace-nowrap", icon_class: "size-4")
    return unless resource&.optimized_audio.present?

    render "shared/play_button", resource: resource, klass: klass, icon_class: icon_class
  end
end
