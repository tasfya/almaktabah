module VideoPlayerHelper
  def video_modal_button(resource:, klass: "btn btn-primary w-fit whitespace-nowrap", icon_class: "size-4")
    return unless resource.respond_to?(:video?) && resource.video?

    render "shared/video_modal_button", resource: resource, klass: klass, icon_class: icon_class
  end

  def youtube_modal_button(resource:, klass: "btn btn-primary w-fit whitespace-nowrap", icon_class: "size-4")
    return unless resource.respond_to?(:youtube_url) && resource.youtube_url.present?

    render "shared/youtube_modal_button", resource: resource, klass: klass, icon_class: icon_class
  end
end
