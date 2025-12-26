require_relative './base'

module Seeds
  class UsersSeeder < Base
    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      puts "Seeding users..."

      admin_user = User.find_or_initialize_by(email: "admin@admin.com") do |user|
        user.password = "qwerty"
        user.password_confirmation = "qwerty"
        user.admin = true
      end

      if admin_user.save
        existing_ids = admin_user.domain_assignments.pluck(:domain_id)
        Array(domain_ids).each do |domain_id|
          next if existing_ids.include?(domain_id)
          DomainAssignment.create!(domain_id: domain_id, assignable: admin_user)
        end
        puts "✅ Admin user created: #{admin_user.email}"
      else
        puts "❌ Failed to create admin user: #{admin_user.errors.full_messages.join(', ')}"
      end

      puts "Seeded 1 user"
    end
  end
end
