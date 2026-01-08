# frozen_string_literal: true

namespace :cache do
  desc "Clear domain content types cache for all domains"
  task clear_content_types: :environment do
    Domain.find_each do |domain|
      DomainContentTypesService.invalidate_cache(domain.id)
      puts "Cleared cache for domain: #{domain.name} (#{domain.id})"
    end
    puts "Done."
  end

  desc "Clear domain content types cache for a specific domain"
  task :clear_content_types_for, [ :domain_id ] => :environment do |_, args|
    domain_id = args[:domain_id]
    abort "Usage: rake cache:clear_content_types_for[domain_id]" if domain_id.blank?

    DomainContentTypesService.invalidate_cache(domain_id)
    puts "Cleared content types cache for domain_id: #{domain_id}"
  end
end
