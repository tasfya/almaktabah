class Avo::Resources::Domain < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :title, as: :text, help: "Site title displayed in browser tab and SEO"
    field :host, as: :text
    field :template_name, as: :select,
          options: -> { Domain.available_templates.map { |t| [ t.humanize, t ] } },
          help: "Choose a template for this domain. Templates define the visual appearance and layout."
    field :active, as: :boolean, help: "Enable/disable this domain"
    field :logo, as: :file, accept: "image/*", max_size: 5.megabytes, hide_on: :index
    field :description, as: :textarea, hide_on: :index
    field :custom_css, as: :code, language: :css, help: "Custom CSS that will be applied to this domain only", hide_on: :index

    field :favicon_ico, as: :file, accept: "image/x-icon,.ico", max_size: 1.megabytes,
          help: "ICO format favicon (optional - auto-generated from logo if not provided)", hide_on: :index
    field :favicon_png, as: :file, accept: "image/png", max_size: 1.megabytes,
          help: "PNG format favicon (optional - auto-generated from logo if not provided)", hide_on: :index
    field :favicon_svg, as: :file, accept: "image/svg+xml", max_size: 1.megabytes,
          help: "SVG format favicon (optional - auto-generated from logo if not provided)", hide_on: :index
    field :apple_touch_icon, as: :file, accept: "image/png", max_size: 1.megabytes,
          help: "Apple touch icon for iOS devices (optional - auto-generated from logo if not provided)", hide_on: :index
  end
end
