module UniversalSlug
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    friendly_id :title, use: [ :slugged, :history ]

    def normalize_friendly_id(input)
      input
        .to_s
        .strip
        .gsub(/\s+/, "-")
        .gsub(/[^\p{L}\p{N}-]/u, "")
    end

    def to_param
      slug
    end

    protected

    def should_generate_new_friendly_id?
      will_save_change_to_title? || slug.blank?
    end
  end
end
