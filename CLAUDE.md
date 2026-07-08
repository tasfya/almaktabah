# almaktabah

Rails 8 app (SQLite + solid_queue, Typesense for search). Ruby is mise-managed
(`mise.toml`). There is intentionally **no `package.json`** — JS is served via
importmap; don't add one.

## Dev workflow (worktrees)

**The main checkout stays on `main` — always.** Other agents work in parallel
from this repo; switching its branch blocks them. Every feature or bug fix
happens in a worktree on its own branch, pushed from there. Never
`git checkout <branch>` in the main checkout. Exception: documentation-only
changes may be committed directly on `main`.

Worktrees live under `.worktrees/` (gitignored) and are managed by
`bin/worktree`:

```sh
bin/worktree new tafsir      # create .worktrees/tafsir on branch `tafsir`, bundle
cd .worktrees/tafsir
bin/worktree serve           # Typesense + db:prepare + Rails, through portless
# ... work, commit, push, open PR from here ...
cd ../..
bin/worktree rm tafsir       # remove the worktree, branch and its Typesense
```

`bin/worktree list` shows what's running.

### How `serve` isolates a worktree

- **URL:** portless derives the hostname from `portless.json` (`almaktabah`)
  plus the branch leaf (last `/`-segment, sanitized). The exact label shape
  depends on your portless/proxy — stock portless gives
  `<leaf>.almaktabah.localhost` (and `almaktabah.localhost` on `main`); the
  single-label fork gives `almaktabah-<leaf>.<tld>`. `serve` prints the URL at
  startup — use that. **Collision risk:** `feat/foo` and `fix/foo` share a
  leaf → same URL; pick unique leaves.
- **Typesense:** its own compose project + volume + host port (`8108` on main,
  `8200-8399` on branches, below the Caddy/proxy ports). Starts empty — reindex if the branch
  needs search. Escape hatch for a port clash:
  `TYPESENSE_PORT=xxxx bin/worktree serve`.
- **Database:** `serve` runs `db:prepare` (seed + reindex) into the worktree's
  own SQLite, with `TYPESENSE_PORT` exported so the reindex targets the right
  instance — don't run `db:prepare`/`db:seed` by hand before it.

### Per-maintainer overrides (`.dev.local`)

Nothing machine-specific is committed. By default `serve` uses plain portless
`*.localhost` URLs. To point at a shared proxy with a custom TLD / trusted
HTTPS, create `.dev.local` (gitignored) at the repo root — `serve` sources it:

```sh
export PORTLESS_STATE_DIR="$HOME/.portless-dev"   # the proxy's state dir
export RAILS_DEVELOPMENT_HOSTS=".example.dev"     # allow the custom TLD
```

`*.localhost` hosts pass Rails host authorization via the `config.hosts` regexp
in `config/environments/development.rb`; a custom TLD needs the
`RAILS_DEVELOPMENT_HOSTS` entry (Rails' built-in mechanism).

### Multi-tenancy on dev URLs

The app is multi-tenant by hostname (`Domain.find_by_host(request.host)`).
Seeds map `127.0.0.1` → Hajri site and `localhost` → ilm site. Portless
hostnames match no Domain row, so in development `set_domain` falls back to the
Hajri domain — every worktree URL serves the main site. To exercise the ilm
tenant, hit the Rails port directly via `http://127.0.0.1:<port>` (printed by
`serve` at startup).

### Tests

Run inside the worktree: `bundle exec rspec` uses the worktree's own test DB
(`storage/test.sqlite3`). The Playwright system specs (`spec/system/`) stub
Typesense and run locally (skipped only in CI). Plain single-checkout dev
(`bin/dev` on `localhost:3000`) still works unchanged.
