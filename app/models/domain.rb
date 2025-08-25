class Domain < ApplicationRecord
  has_one_attached :logo, service: Rails.application.config.public_storage
  has_one_attached :art_work, service: Rails.application.config.public_storage
  has_one_attached :favicon_ico, service: Rails.application.config.public_storage
  has_one_attached :favicon_png, service: Rails.application.config.public_storage
  has_one_attached :favicon_svg, service: Rails.application.config.public_storage
  has_one_attached :apple_touch_icon, service: Rails.application.config.public_storage
  has_many :domain_assignments, dependent: :destroy

  def self.find_by_host(host)
    find_by(host: host)
  end

  def assigned_items
    domain_assignments.includes(:assignable)
  end

  def has_custom_css?
    custom_css.present?
  end

  def has_custom_favicons?
    favicon_ico.present? || favicon_png.present? || favicon_svg.present? || apple_touch_icon.present?
  end

  def should_auto_generate_favicons?
    logo.attached? && !has_custom_favicons?
  end
end
