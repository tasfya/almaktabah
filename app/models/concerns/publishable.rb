module Publishable
  extend ActiveSupport::Concern

  included do
    # Add published_at column as datetime if it doesn't exist
    # This will be set automatically when published is changed to true
    before_save :set_published_at

    validates :published, inclusion: { in: [ true, false ] }

    # Scopes
    scope :published, -> { where(published: true) }
    scope :unpublished, -> { where(published: false) }
  end

  private

  def set_published_at
    # Set published_at to current time when published is set to true
    if published_changed? && published == true
      self.published_at = Time.current
    elsif published_changed? && published == false
      self.published_at = nil
    end
  end
end
