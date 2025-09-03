module Sluggable
  extend ActiveSupport::Concern

  included do
    include ArabicHelper
    include TextHelper

    extend FriendlyId
    friendly_id :title, use: [ :slugged, :history, :sequentially_slugged ]

    def normalize_friendly_id(value, sep: "-")
      normalize_for_slug(value, separator: sep)
    end

    def to_param
      slug || super
    end

    protected

    def should_generate_new_friendly_id?
      will_save_change_to_title? || slug.blank?
    end
  end
end
