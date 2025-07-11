module Publishable
  extend ActiveSupport::Concern

  included do
    before_save :set_published_at

    validates :published, inclusion: { in: [ true, false ] }

    scope :published, -> { where(published: true) }
    scope :unpublished, -> { where(published: false) }
  end

  private

  def set_published_at
    # Set published_at to current time when published is set to true and published_at is blank
    if published_changed? && published == true && published_at.blank?
      self.published_at = Time.current
    elsif published_changed? && published == false
      self.published_at = nil
    end
  end
end
