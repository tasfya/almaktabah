namespace :api do
  desc "Generate an API token for a user"
  task :generate_token, [ :email, :purpose, :rate_limit ] => :environment do |t, args|
    # Support both traditional args[:email] and ENV['email'] styles
    # This makes it work with ZSH that has issues with square brackets
    email = args[:email] || ENV['email']
    purpose = args[:purpose] || ENV['purpose'] || "API Access"

    if email.blank?
      puts "Email is required. Usage: rake api:generate_token[user@example.com,\"Frontend API\",100]"
      puts "For ZSH users: rake api:generate_token email=user@example.com purpose=\"Frontend API\" rate_limit=100"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email #{email} not found."
      next
    end

    token = user.create_api_token(purpose: purpose, rate_limit: rate_limit.to_i)
    
    puts "API token for #{email} (#{purpose}): #{token.token}"
    puts "This token will expire on: #{token.expires_at}"
    puts "Store this token securely - it won't be shown again!"
  end

  desc "List all API tokens for a user"
  task :list_tokens, [ :email ] => :environment do |t, args|
    # Support both traditional args[:email] and ENV['email'] styles
    email = args[:email] || ENV['email']

    if email.blank?
      puts "Email is required. Usage: rake api:list_tokens[user@example.com]"
      puts "For ZSH users: rake api:list_tokens email=user@example.com"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "User with email #{email} not found."
      next
    end

    tokens = user.api_tokens

    if tokens.empty?
      puts "No API tokens found for #{email}."
      next
    end

    puts "API tokens for #{email}:"
    tokens.each do |token|
      status = if !token.active?
                "INACTIVE"
              elsif token.expired?
                "EXPIRED"
              else
                "ACTIVE"
              end
      
      puts "- ID: #{token.id}"
      puts "  Purpose: #{token.purpose}"
      puts "  Token: #{token.token[0..10]}..."
      puts "  Status: #{status}"
      puts "  Requests used: #{token.requests_count} (resets at #{token.reset_at || 'N/A'})"
      puts "  Last used: #{token.last_used_at || 'Never'}"
      puts "  Expires: #{token.expires_at}"
      puts "  Created: #{token.created_at}"
      puts ""
    end
  end

  desc "Revoke an API token"
  task :revoke_token, [ :token_id ] => :environment do |t, args|
    # Support both traditional args[:token_id] and ENV['token_id'] styles
    token_id = args[:token_id] || ENV['token_id']

    if token_id.blank?
      puts "Token ID is required. Usage: rake api:revoke_token[123]"
      puts "For ZSH users: rake api:revoke_token token_id=123"
      next
    end

    token = ApiToken.find_by(id: token_id)

    if token.nil?
      puts "Token with ID #{token_id} not found."
      next
    end

    token.revoke
    
    puts "Token #{token_id} for #{token.user.email} has been revoked."
  end
end
