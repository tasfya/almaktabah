#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Create a new scholar
new_scholar = Scholar.create!(
  first_name: "عبدالله",
  last_name: "بن عبدالرحمن الجبرين",
  published: true
)

puts "Created scholar: #{new_scholar.name} (ID: #{new_scholar.id})"

# Assign the scholar to the second domain (localhost, ID: 2)
domain_id = 2
domain = Domain.find(domain_id)
puts "Assigning to domain: #{domain.host} (ID: #{domain.id})"

# Create domain assignment
DomainAssignment.create!(
  domain: domain,
  assignable: new_scholar
)

puts "Successfully assigned #{new_scholar.name} to #{domain.host}"
puts "Assignment created with ID: #{new_scholar.domain_assignments.last.id}"
