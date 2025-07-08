# Almaktabah( Tasfiya)

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

