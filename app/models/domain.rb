class Domain < ApplicationRecord
  has_one_attached :logo, service: Rails.application.config.public_storage
  has_one_attached :art_work, service: Rails.application.config.public_storage
  has_many :domain_assignments, dependent: :destroy

  def self.find_by_host(host)
    find_by(host: host)
  end

  def assigned_items
    domain_assignments.includes(:assignable)
  end
end
