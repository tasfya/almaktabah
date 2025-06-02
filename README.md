# Almaktabah

This is the README for Almaktabah application.

## Admin Dashboard

The application includes an admin dashboard powered by [Avo](https://avohq.io/). The dashboard is protected and only accessible to admin users.

### Managing Admin Users

To create or promote a user to admin, use the following rake task:

```bash
# Create a new user with admin privileges
rails runner "User.create!(email: 'admin@example.com', password: 'password123', password_confirmation: 'password123', admin: true)"

# Promote an existing user to admin
bin/rake users:make_admin[user@example.com]

# List all admin users
bin/rake users:list_admins
```

The admin dashboard is available at `/avo` and requires admin user credentials to access.

## API Authentication

The API is protected with token-based authentication. There are two ways to authenticate:

1. JWT tokens for user-specific operations (login, profile, etc.)
2. API tokens for general data access (e.g. from the frontend application)

### Managing API Tokens

API tokens can be generated and managed in the following ways:

#### From the Admin Dashboard

1. Log in to the admin dashboard at `/avo`
2. Navigate to the Users section
3. Open a user record
4. Click the "Generate API Token" action
5. Enter a purpose for the token (e.g., "Frontend API")
7. Save the token securely, as it won't be displayed again

To update the rate limit for an existing token:
1. Navigate to the API Tokens section
2. Select the token you want to modify
3. Click the "Update Rate Limit" action
4. Enter the new rate limit value

#### Using Rake Tasks

```bash
# Generate a new API token for a user with rate limit (Bash)
bin/rake api:generate_token[user@example.com,"Frontend API"]

# For ZSH users:
bin/rake api:generate_token email=user@example.com purpose="Frontend API"

# List all API tokens for a user (Bash)
bin/rake api:list_tokens[user@example.com]

# For ZSH users:
bin/rake api:list_tokens email=user@example.com

# Revoke a token (Bash)
bin/rake api:revoke_token[token_id]

# For ZSH users:
bin/rake api:revoke_token token_id=123

# For ZSH users:
bin/rake api:update_rate_limit token_id=123 rate_limit=500

```

### Using API Tokens in the Frontend

Add the API token to your frontend's environment variables:

1. Copy the `.env.local.example` file to `.env.local` in the frontend directory
2. Add your API token to the `NEXT_PUBLIC_API_TOKEN` variable

The frontend API client will automatically include the token in all requests.

### API Token in HTTP Requests

You can include the API token in your requests in one of these ways:

1. As an HTTP header: `X-API-Token: your_token_here`
2. As a query parameter: `?api_token=your_token_here`