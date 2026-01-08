class DomainAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true
  belongs_to :domain

  after_commit :invalidate_domain_content_types_cache

  private

  def invalidate_domain_content_types_cache
    DomainContentTypesService.invalidate_cache(domain_id) if domain_id.present?
  end
end
