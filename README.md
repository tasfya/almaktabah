# Almaktabah (Tasfiya)

This is the README for Almaktabah application.

## Contributing

- Fork and clone the repository.
- Run `bundle install` to install dependencies.
- Install pre-commit hooks: `bundle exec overcommit --install`.
- Set up the database with `bin/setup`.
- Start the server with `bin/dev`.
- Make your changes in a new branch.
- Ensure tests pass with `bundle exec rspec`.
- (Optional) Seed the database with `bin/rails db:seed` for sample data.
- Follow the code style using `bundle exec rubocop` (enforced via pre-commit hook).
- Submit a pull request.

## Admin Dashboard

The application includes an admin dashboard powered by [Avo](https://avohq.io/). The dashboard is protected and only accessible to admin users.

The admin dashboard is available at `/avo` and requires admin user credentials to access.

## Managing Admin Users

To create or promote a user to admin, use the following rake task:

```bash
# Create a new user with admin privileges
rails runner "User.create!(email: 'admin@example.com', password: 'password123', password_confirmation: 'password123', admin: true)"

# Promote an existing user to admin
bin/rake users:make_admin[user@example.com]

# List all admin users
bin/rake users:list_admins
```

## Styling Framework

This application uses **Tailwind CSS 4** with **daisyUI** for styling and UI components. Propshaft will automatically handle the asset pipeline for these files. If the changes are not reflected, run `bin/rails assets:clobber` to clear compiled assets.

### Upgrading daisyUI

For upgrading daisyUI, we use the bundle file method. Follow these steps from the [daisyUI Rails installation guide](https://daisyui.com/docs/install/rails/):

1. Download the latest daisyUI bundle files:

   ```bash
   curl -sLo app/assets/tailwind/daisyui.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js
   curl -sLo app/assets/tailwind/daisyui-theme.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.js
   ```

## API Documentation

This application uses [Rswag](https://github.com/rswag/rswag) to generate and serve Swagger UI for API documentation.

### Accessing Swagger UI

In development, the Swagger UI is available at:

```
http://localhost:3000/api-docs
```

### Updating API Documentation

When you make changes to API endpoints or data structures, update the Swagger documentation by running:

```bash
bundle exec rake rswag
```

This command generates the OpenAPI JSON files from your RSpec API tests, which are then served by the Swagger UI.
