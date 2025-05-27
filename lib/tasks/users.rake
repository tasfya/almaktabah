namespace :users do
  desc "Promote a user to admin"
  task :make_admin, [ :email ] => :environment do |t, args|
    email = args[:email]

    if email.blank?
      puts "Email is required. Usage: rake users:make_admin[user@example.com]"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email #{email} not found."
      next
    end

    if user.admin?
      puts "User #{email} is already an admin."
      next
    end

    user.update(admin: true)
    puts "User #{email} has been promoted to admin."
  end

  desc "List all admin users"
  task list_admins: :environment do
    admins = User.where(admin: true)

    if admins.empty?
      puts "No admin users found."
      next
    end

    puts "Admin users:"
    admins.each do |admin|
      puts "- #{admin.email} (ID: #{admin.id})"
    end
  end
end
