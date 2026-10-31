# Testing almaktabah

## Running the suite

```sh
bin/worktree test                       # whole suite, with a throwaway Typesense
bin/worktree test spec/requests         # a subset (args pass through to rspec)
bin/worktree test --only-failures       # rerun what failed last time
```

`bin/worktree test` starts a test-only Typesense container (its own port,
compose project and volume, never your dev index) and sets
`RUN_TYPESENSE_SPECS=1`. Plain `bundle exec rspec` also works but skips every
`:typesense` example.

- **Order is random.** The seed is printed at the start and end of every run;
  reproduce an order-dependent failure with `--seed <n>`.
- `spec/examples.txt` (gitignored) records each example's last status, which
  powers `--only-failures` and `--next-failure`.
- The 10 slowest examples are listed after each run.
- `fit` / `fdescribe` run only the focused examples locally; RuboCop's
  `RSpec/Focus` keeps them out of `main`.
- **The network is off.** WebMock blocks every HTTP request except localhost
  (Typesense, the Capybara server). Stub external calls with
  `stub_request(:get, "https://...")`.

## Coverage

SimpleCov records line and branch coverage, including ERB views
(`enable_coverage_for_eval`). Open `coverage/index.html` after a run; CI
uploads `coverage/coverage.xml` (Cobertura) to Codecov.

- Only templates that some spec renders are counted, so an untested view
  does not lower the number. Treat view coverage as "what is exercised", not
  "what exists".
- The floor (`minimum_coverage` in `spec/spec_helper.rb`) is enforced only
  when `CI` is set, because a partial local run is always below it. Raise it
  when coverage goes up; never lower it to get a PR through.
- CI eager-loads the app (`config.eager_load = ENV["CI"].present?`), so its
  numbers differ from a local run's. Compare with `CI=1 bin/worktree test`.
- Codecov comments on PRs (project: no drop over 1%; patch: 80%) but its
  statuses are informational, not required checks.

## Layers

| Layer | Where | Use it for |
|---|---|---|
| Unit | `spec/models`, `spec/services`, `spec/helpers`, `spec/jobs` | Logic of one object. Fast, no HTTP. |
| Request | `spec/requests` | One HTTP request in, response out: status, redirects, rendered HTML/XML, tenant scoping, SEO tags. The default layer for anything a URL serves. |
| Typesense integration | `spec/integration`, tagged `:typesense` | Indexing real records into a real Typesense and reading them back through the search services. |
| System (JS) | `spec/system`, `js: true` | Behaviour that needs a browser: Stimulus/Turbo interactions, history navigation. Playwright Chromium. Slow; keep it for what only a browser can show. |

### Real Typesense vs stubs

- Anything that depends on **what the search returns** (filters, facets,
  domain scoping of listings, ranking) belongs in a `:typesense` spec that
  indexes real records with `index_records(...)`. The harness empties every
  collection before and after each example.
- A spec that only needs *some* search result to render a page may stub the
  service. In new code stub one instance with `instance_double` and inject or
  `allow(Service).to receive(:new).and_return(double)`; **never
  `allow_any_instance_of`**. RuboCop's `RSpec/AnyInstance` enforces this; the
  few older uses are excluded by file in `.rubocop.yml`.

## Multi-tenancy

Every public page is served for the `Domain` whose `host` matches the request
host. In request specs:

```ruby
include_context "with tenant domain"            # domain at "localhost", other_domain at "other.example.com"
let(:tenant_host) { "www.example.com" }         # optional override
let(:tenant_domain_attributes) { { name: "Test Site" } }
```

or, for a one-off host, `with_domain("example.com", name: "X")`, which creates
the Domain and points the following requests at it.

Content is visible on a domain only when it is published and assigned to it
(`record.domains << domain` or `record.assign_to(domain)`). To cover a new
show page, use the shared examples:

```ruby
it_behaves_like "a domain-scoped show page",
  record: ->(published:) { create(:book, scholar: scholar, published: published, published_at: (1.day.ago if published)) },
  path: ->(book) { book_path(book.scholar, book) },
  not_found_path: -> { books_path },
  not_found: "messages.book_not_found"
```

It checks the three cases: served on its domain, redirected when only on
another domain, redirected when unpublished. See
`spec/requests/show_scoping_spec.rb`.

Listing pages read from Typesense, so their domain scoping is tested in the
`:typesense` specs, not with this shared example.

## Factories

- `spec/factories_spec.rb` runs `FactoryBot.lint(traits: true)`: every factory
  and trait must build a valid record. Add a trait, and it is checked.
- Values that end up in URLs or unique columns are deterministic or
  sequenced (`kind { :sermon }`, `sequence(:host)`), never `sample` or a Faker
  value with a small range. A random slug-forming value makes a spec pass or
  fail by seed.
- Associations are built by the factory (`association(:scholar)`), not left
  `nil`.
- Factories never touch the network.

## Assertions

Parse markup instead of grepping the body. In request specs:

| Helper / matcher | Checks |
|---|---|
| `have_html_title(expected)` | `<title>` text |
| `have_meta_tag(name_or_property, expected = nil)` | `<meta name=…>` or `<meta property=…>` exists, optionally its `content` |
| `have_canonical(expected)` | `<link rel="canonical">` href |
| `have_sitemap_locs(*urls)` | every URL is among the sitemap `<loc>`s |
| `sitemap_locs` | array of `<loc>` texts, for exact `eq` |
| `json_ld` | parsed JSON-LD objects in the page |
| `html` | Nokogiri document of the response, for anything else |

Each expected value can be a composable matcher, e.g.
`have_html_title(a_string_starting_with("Book"))`. Each matcher also accepts a
plain string instead of `response`.

`have_title` is Capybara's matcher for system specs; in request specs use
`have_html_title`.

## Regression / characterization recipe

Public URLs are indexed by Google. A refactor must not change a URL, a
redirect, a sitemap entry or the SEO tags of a page unless that change is the
point of the PR.

The URL contract already pins the public surface with literal paths and
golden files: `spec/requests/url_contract_spec.rb` (one show URL per type),
`spec/requests/url_contract/` (redirects, sitemaps, podcast feed, `<head>`
snapshots, known issues) and `spec/routing/public_routes_spec.rb` (routes
table). Its expected URLs are literal on purpose; never rebuild them with
route helpers or `I18n.t`.

Before refactoring code that renders or routes public pages:

1. **Pin current behaviour** on `main`: write request specs for the URLs,
   redirects and tags involved, and, for whole documents, a golden file:

   ```ruby
   expect(response).to match_golden("sitemaps/static.xml")
     .normalized_by { |xml| xml.gsub(/\d{4}-\d{2}-\d{2}/, "YYYY-MM-DD") }
   ```

   Create the file with `UPDATE_GOLDEN=1 bin/worktree test <spec>`; it lands
   under `spec/fixtures/golden/` and is committed.
2. Make the golden output stable: create records with fixed titles/slugs, and
   normalize what still varies (dates, ids, asset digests). A golden of a full
   HTML page churns on every layout or CSS change; prefer XML, text, JSON-LD or
   a fragment (`html.at_css("main").to_html`).
3. Refactor. The pinned specs must pass unchanged.
4. If an output change is intended, regenerate with `UPDATE_GOLDEN=1` and
   review the golden-file diff in the PR like any other code.
