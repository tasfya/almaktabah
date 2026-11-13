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

## Releasing

The pipeline is the only path to production. Staging and production change
only through two GitHub Actions workflows:

- **Deployment** runs after CI passes on `main`: it builds the app image once,
  deploys it to staging, smoke checks staging, then deploys the same image to
  production.
- **Rollback** boots a previous release on demand (see below).

Accessories (Typesense, Litestream) are part of that: change their config in
`config/deploy.yml` or `kamal_config/deploy.staging.yml` and merge, and the
next deployment reboots the ones whose config changed. Don't run `kamal
deploy`, `kamal accessory reboot` or other changing `kamal` commands against
the servers from a laptop: the release would be one CI never checked, and the
repository would no longer describe what runs. Read-only commands (`kamal app
logs`, `kamal app details`, `kamal accessory details`) are fine.

The one manual step is upgrading kamal-proxy on the host when a Kamal upgrade
requires a newer proxy (`kamal deploy` then fails with "kamal-proxy version …
is too old"). It restarts the proxy, a brief outage for every site on the host.

## Stop the line

When CI or Deployment fails on `main`, the **Main status** workflow opens a
"main is red" issue (or comments on the open one), which notifies everyone
watching the repository. A red `main` is fixed or reverted before any other
change merges: until it is green, nothing reaches production. The issue closes
itself on the next successful deployment.

## Rolling back a release

Run the **Rollback** workflow (Actions → Rollback → Run workflow) and pick the
environment:

1. Leave `version` empty first: the run lists the app containers on the host.
   Each release is tagged with its full git SHA; Kamal keeps the last 5, so
   only those can be rolled back to. The SHAs of past releases are also in the
   Deployment runs' history.
2. Run it again with that SHA as `version`. The run fails if the host is not
   running that version afterwards.

A rollback only swaps the app containers; the database stays as it is.
That makes two rules matter:

- **Migrations must work with the previous release.** Change the schema in
  backwards-compatible steps (expand, then contract in a later release): add
  columns and tables before code uses them, and drop or rename them only once
  no deployed release reads them. Then the previous release can run against
  the migrated database.
- **Restore from Litestream instead** when the bad release damaged data, or ran
  a migration the previous release cannot run against. Rolling the code back
  does not undo either.

The next green `main` deploys again, so fix or revert the bad commit on
`main` after rolling back.

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

## Scripts

### Bulk S3 audio transcription (`scripts/s3_transcriber.py`)

Transcribes every audio file under an S3 prefix locally with Whisper and
writes a CSV manifest mapping each S3 key to its transcription file. Useful
for identifying unlabeled audio (unknown scholar/title) by skimming the
transcript preview instead of listening to every file.

```bash
# uses the existing myenv virtualenv (faster-whisper + torch/CUDA already installed)
myenv/bin/pip install boto3   # first time only
myenv/bin/python3 scripts/s3_transcriber.py --bucket backups-afsolama --prefix miraath/
```

- AWS credentials come from the normal AWS CLI chain (`~/.aws/credentials`) —
  nothing extra to configure if `aws s3 ls` already works on the machine.
- Output: `s3_transcriptions.csv` (`s3_key, status, transcription_file,
  duration_seconds, language, text_preview`) plus one JSON transcript per
  audio file under `~/s3_transcriptions/` (configurable via `OUTPUT_CSV` /
  `OUTPUT_DIR` env vars).
- Resumable: re-running skips keys already marked `ok` in the CSV, and each
  row is flushed immediately so interrupting with Ctrl-C loses no progress.
- Set `TRANSCRIPTION_LIMIT` to do a small test run before a full pass. See
  the script's module docstring for the full list of environment variables.

## Styling Framework

This application uses **Tailwind CSS 4** with **daisyUI** for styling and UI components. Propshaft will automatically handle the asset pipeline for these files. If the changes are not reflected, run `bin/rails assets:clobber` to clear compiled assets.

### Upgrading daisyUI

For upgrading daisyUI, we use the bundle file method. Follow these steps from the [daisyUI Rails installation guide](https://daisyui.com/docs/install/rails/):

1. Download the latest daisyUI bundle files:

   ```bash
   curl -sLo app/assets/tailwind/daisyui.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.js
   curl -sLo app/assets/tailwind/daisyui-theme.js https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.js
   ```
