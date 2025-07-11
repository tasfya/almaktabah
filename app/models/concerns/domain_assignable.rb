module DomainAssignable
  extend ActiveSupport::Concern

  included do
    has_many :domain_assignments, as: :assignable, dependent: :destroy
    has_many :domains, through: :domain_assignments
  end

  def assigned_to?(domain)
    domain_assignments.exists?(domain: domain)
  end

  def assign_to(domain)
    assignment = domain_assignments.find_or_initialize_by(domain: domain)
    assignment.save!
  end

  def unassign_from(domain)
    domain_assignments.where(domain: domain).destroy_all
  end

  def assigned_domains
    domains
  end
end
