require_relative './base'

module Seeds
  class UsersSeeder < Base
    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      puts "Seeding users..."

      # A publicly reachable deploy (staging runs RAILS_ENV=production) must not
      # get the well-known dev password; set SEED_ADMIN_PASSWORD or reset it
      # from a console.
      password = ENV["SEED_ADMIN_PASSWORD"].presence ||
        (Rails.env.production? ? SecureRandom.base58(32) : "qwerty")

      admin_user = User.find_or_initialize_by(email: "admin@admin.com") do |user|
        user.password = password
        user.password_confirmation = password
        user.admin = true
      end

      if admin_user.save
        puts "✅ Admin user created: #{admin_user.email}"
      else
        puts "❌ Failed to create admin user: #{admin_user.errors.full_messages.join(', ')}"
      end

      puts "Seeded 1 user"
    end
  end
end
