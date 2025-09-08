namespace :domain_scholars do
  desc "Assign a scholar to a domain"
  task :assign, [ :host, :scholar_id ] => :environment do |task, args|
    if args[:host].blank?
      puts "Error: Host is required"
      puts "Usage: rails domain_scholars:assign[host,scholar_id]"
      puts "Example: rails domain_scholars:assign[binramzan.net,1]"
      exit 1
    end

    domain = Domain.find_by(host: args[:host])
    unless domain
      puts "Error: Domain with host '#{args[:host]}' not found"
      exit 1
    end

    if args[:scholar_id].blank?
      puts "Error: Scholar ID is required"
      puts "Usage: rails domain_scholars:assign[host,scholar_id]"
      puts "Example: rails domain_scholars:assign[binramzan.net,1]"
      exit 1
    end

    scholar = Scholar.find_by(id: args[:scholar_id])
    unless scholar
      puts "Error: Scholar with ID '#{args[:scholar_id]}' not found"
      exit 1
    end

    # Check if assignment already exists
    existing_assignment = DomainAssignment.find_by(domain: domain, assignable: scholar)
    if existing_assignment
      puts "Scholar '#{scholar.name}' is already assigned to domain '#{domain.host}'"
      exit 0
    end

    # Create the assignment
    DomainAssignment.create!(domain: domain, assignable: scholar)
    puts "Successfully assigned scholar '#{scholar.name}' (ID: #{scholar.id}) to domain '#{domain.host}'"
  end

  desc "Assign all scholars to a domain"
  task :assign_all, [ :host ] => :environment do |task, args|
    if args[:host].blank?
      puts "Error: Host is required"
      puts "Usage: rails domain_scholars:assign_all[host]"
      puts "Example: rails domain_scholars:assign_all[3ilm.org]"
      exit 1
    end

    domain = Domain.find_by(host: args[:host])
    unless domain
      puts "Error: Domain with host '#{args[:host]}' not found"
      exit 1
    end

    scholars = Scholar.published
    if scholars.empty?
      puts "No published scholars found"
      exit 0
    end

    assigned_count = 0
    scholars.each do |scholar|
      # Check if assignment already exists
      existing_assignment = DomainAssignment.find_by(domain: domain, assignable: scholar)
      unless existing_assignment
        DomainAssignment.create!(domain: domain, assignable: scholar)
        assigned_count += 1
        puts "Assigned scholar '#{scholar.name}' (ID: #{scholar.id}) to domain '#{domain.host}'"
      end
    end

    puts "Successfully assigned #{assigned_count} scholars to domain '#{domain.host}'"
    puts "Total scholars now assigned to this domain: #{domain.domain_assignments.where(assignable_type: 'Scholar').count}"
  end

  desc "Remove scholar assignment from a domain"
  task :remove, [ :host, :scholar_id ] => :environment do |task, args|
    if args[:host].blank?
      puts "Error: Host is required"
      puts "Usage: rails domain_scholars:remove[host,scholar_id]"
      puts "Example: rails domain_scholars:remove[binramzan.net,1]"
      exit 1
    end

    domain = Domain.find_by(host: args[:host])
    unless domain
      puts "Error: Domain with host '#{args[:host]}' not found"
      exit 1
    end

    if args[:scholar_id].blank?
      puts "Error: Scholar ID is required"
      puts "Usage: rails domain_scholars:remove[host,scholar_id]"
      puts "Example: rails domain_scholars:remove[binramzan.net,1]"
      exit 1
    end

    scholar = Scholar.find_by(id: args[:scholar_id])
    unless scholar
      puts "Error: Scholar with ID '#{args[:scholar_id]}' not found"
      exit 1
    end

    assignment = DomainAssignment.find_by(domain: domain, assignable: scholar)
    unless assignment
      puts "Scholar '#{scholar.name}' is not assigned to domain '#{domain.host}'"
      exit 0
    end

    assignment.destroy!
    puts "Successfully removed scholar '#{scholar.name}' (ID: #{scholar.id}) from domain '#{domain.host}'"
  end

  desc "Remove all scholar assignments from a domain"
  task :remove_all, [ :host ] => :environment do |task, args|
    if args[:host].blank?
      puts "Error: Host is required"
      puts "Usage: rails domain_scholars:remove_all[host]"
      puts "Example: rails domain_scholars:remove_all[binramzan.net]"
      exit 1
    end

    domain = Domain.find_by(host: args[:host])
    unless domain
      puts "Error: Domain with host '#{args[:host]}' not found"
      exit 1
    end

    assignments = domain.domain_assignments.where(assignable_type: "Scholar")
    count = assignments.count

    if count == 0
      puts "No scholar assignments found for domain '#{domain.host}'"
      exit 0
    end

    assignments.destroy_all
    puts "Successfully removed #{count} scholar assignments from domain '#{domain.host}'"
  end

  desc "List all scholar assignments for a domain"
  task :list, [ :host ] => :environment do |task, args|
    if args[:host].blank?
      puts "Error: Host is required"
      puts "Usage: rails domain_scholars:list[host]"
      puts "Example: rails domain_scholars:list[binramzan.net]"
      exit 1
    end

    domain = Domain.find_by(host: args[:host])
    unless domain
      puts "Error: Domain with host '#{args[:host]}' not found"
      exit 1
    end

    scholar_assignments = domain.domain_assignments.includes(:assignable).where(assignable_type: "Scholar")

    puts "Scholar assignments for domain '#{domain.host}':"
    puts "=" * 50

    if scholar_assignments.empty?
      puts "No scholars assigned to this domain"
    else
      scholar_assignments.each do |assignment|
        scholar = assignment.assignable
        puts "- #{scholar.name} (ID: #{scholar.id})"
      end
      puts "\nTotal: #{scholar_assignments.count} scholars"
    end
  end

  desc "List all available scholars"
  task list_scholars: :environment do
    scholars = Scholar.published.order(:first_name, :last_name)

    puts "Available scholars:"
    puts "=" * 50

    if scholars.empty?
      puts "No published scholars found"
    else
      scholars.each do |scholar|
        puts "- #{scholar.name} (ID: #{scholar.id})"
      end
      puts "\nTotal: #{scholars.count} scholars"
    end
  end

  desc "List all available domains"
  task list_domains: :environment do
    domains = Domain.order(:host)

    puts "Available domains:"
    puts "=" * 50

    if domains.empty?
      puts "No domains found"
    else
      domains.each do |domain|
        scholar_count = domain.domain_assignments.where(assignable_type: "Scholar").count
        puts "- #{domain.host} (#{scholar_count} scholars assigned)"
      end
      puts "\nTotal: #{domains.count} domains"
    end
  end
end
