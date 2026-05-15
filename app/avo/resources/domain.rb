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

    # Podcast settings
    field :podcast_enabled, as: :boolean, help: "Enable podcast RSS feed for this domain"
    field :podcast_title, as: :text, help: "Podcast title (required)"
    field :podcast_author, as: :text, help: "Podcast author name"
    field :podcast_description, as: :textarea, help: "Podcast description", hide_on: :index
    field :podcast_owner_name, as: :text, help: "Owner name for iTunes/Spotify", hide_on: :index
    field :podcast_owner_email, as: :text, help: "Owner email for iTunes/Spotify (required)", hide_on: :index
    field :podcast_language, as: :text, help: "Language code (e.g., ar, en)", hide_on: :index
    field :podcast_category, as: :select, hide_on: :index,
          options: [
            "Arts",
            "Business",
            "Comedy",
            "Education",
            "Fiction",
            "Government",
            "Health & Fitness",
            "History",
            "Kids & Family",
            "Leisure",
            "Music",
            "News",
            "Religion & Spirituality",
            "Science",
            "Society & Culture",
            "Sports",
            "Technology",
            "True Crime",
            "TV & Film"
          ],
          help: "Apple Podcasts category"
    field :podcast_subcategory, as: :text, help: "Subcategory (e.g., Islam)", hide_on: :index
    field :podcast_artwork, as: :file, accept: "image/jpeg,image/png", max_size: 5.megabytes,
          help: "Podcast artwork (1400x1400 to 3000x3000 pixels, JPEG or PNG)", hide_on: :index
    field :podcast_artwork_url_override, as: :text, hide_on: :index,
          help: "Direct URL to artwork image (must end in .jpg or .png). Use this instead of uploading if needed."
  end
end
