class Domain < ApplicationRecord
  has_many :domain_assignments, dependent: :destroy

  def self.find_by_host(host)
    find_by(host: host)
  end

  def assigned_items
    domain_assignments.includes(:assignable)
  end
end
