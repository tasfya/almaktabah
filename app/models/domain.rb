class Domain < ApplicationRecord
  has_one_attached :logo, service: Rails.application.config.public_storage
  has_one_attached :art_work, service: Rails.application.config.public_storage
  has_one_attached :favicon_ico, service: Rails.application.config.public_storage
  has_one_attached :favicon_png, service: Rails.application.config.public_storage
  has_one_attached :favicon_svg, service: Rails.application.config.public_storage
  has_one_attached :apple_touch_icon, service: Rails.application.config.public_storage
  has_many :domain_assignments, dependent: :destroy
  has_many :scholars, foreign_key: :default_domain_id

  validate :template_name_must_be_valid

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

  def self.available_templates
    template_dirs = []

    templates_path = Rails.root.join("app", "views", "templates")
    if Dir.exist?(templates_path)
      template_dirs = Dir.glob("#{templates_path}/*").select { |f| File.directory?(f) }.map { |dir| File.basename(dir) }
    end

    ([ "default" ] + template_dirs).uniq.sort
  end

  def template_path
    return "templates/#{template_name}" if template_name.present? && template_name != "default"
    nil
  end

  def template_name_must_be_valid
    return false if template_name.blank?
    return false if !self.class.available_templates.include?(template_name)
    true
  end
end
