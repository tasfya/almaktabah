class DomainAssignment < ApplicationRecord
  belongs_to :assignable, polymorphic: true
  belongs_to :domain
end
