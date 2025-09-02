module AudioPlayerHelper
  def play_button(resource:, klass: "btn btn-secondary w-fit whitespace-nowrap", icon_class: "size-4")
    return unless resource.respond_to?(:has_any_audio?) && resource.has_any_audio?

    render "shared/play_button", resource: resource, klass: klass, icon_class: icon_class
  end
end
