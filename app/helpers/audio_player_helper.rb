module AudioPlayerHelper
  def play_button(resource:, klass: "btn btn-secondary w-fit whitespace-nowrap", icon_class: "size-4", is_playing: false, &block)
    return unless resource.respond_to?(:has_any_audio?) && resource.has_any_audio?

    custom_content = block_given? ? capture(&block) : nil

    render "shared/play_button", resource: resource, klass: klass, icon_class: icon_class, custom_content: custom_content, is_playing: is_playing
  end
end
