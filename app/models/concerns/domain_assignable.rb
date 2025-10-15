module DomainAssignable
  extend ActiveSupport::Concern

  included do
    has_many :domain_assignments, as: :assignable, dependent: :destroy
    has_many :domains, through: :domain_assignments
    scope :for_domain_id, ->(domain_id) {
      joins(:domain_assignments).where(domain_assignments: { domain_id: domain_id })
    }
    after_save :ensure_default_domain_assignment
  end

  def ensure_default_domain_assignment
    if scholar&.default_domain.present? && !assigned_to?(scholar.default_domain)
      assign_to(scholar.default_domain)
    end
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
