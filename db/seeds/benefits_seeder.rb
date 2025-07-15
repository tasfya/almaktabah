require_relative './base'

module Seeds
  class BenefitsSeeder < Base
    def self.seed(from: nil, domain_id: nil)
      BenefitImportService.import_all(from: from, domain_id: domain_id)
    end
  end
end
