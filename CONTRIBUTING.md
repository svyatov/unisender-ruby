# Contributing

Contributions and questions are welcome through the [issue tracker](https://github.com/svyatov/unisender-ruby/issues). Include the Ruby and gem versions, a minimal example with fake values, expected behavior, and a redacted exception message. Do not post API keys, contact data, export links, or raw request/response bodies.

## Set up

Use Ruby 3.3 or newer and Bundler. CI checks Ruby 3.3, 3.4, and 4.0. Install [Betterleaks](https://github.com/betterleaks/betterleaks) using its upstream installation instructions and ensure `betterleaks` is on `PATH`. Then run:

```sh
bin/setup
bundle exec rake check
```

`bin/setup` installs development dependencies and Lefthook hooks. The complete check runs offline tests, RuboCop, RBS validation, Steep for the library and consumer examples, the dependency vulnerability audit, and the gem build. The audit updates its advisory database and needs network access.

CI runs `bundle exec rake ci` for lint, tests, types, and the build. Dependency review blocks newly introduced vulnerabilities. A separate advisory job reports vulnerabilities across the lockfile without blocking unrelated changes.

## Make a change

Use a branch such as `fix/error-context` or `feat/new-operation`. Read the official UniSender method documentation before changing a wire contract. Add a regression test with a deterministic transport, keep signatures in `sig/` synchronized, update the relevant docs, and add an entry under Unreleased in [CHANGELOG.md](CHANGELOG.md).

Follow the repository requirements in [AGENTS.md](AGENTS.md) and the [code of conduct](CODE_OF_CONDUCT.md). New functionality must include tests.

Fork the repository and create your branch from `main`. Push the branch to your fork, then open a pull request against `svyatov/unisender-ruby:main`. Describe the affected public interface and include the evidence needed to assess the change. Keep unrelated changes in separate pull requests. Maintainers use squash merges.

| Command | Purpose |
| --- | --- |
| `bundle exec rake test` | Minitest with 100% line and branch coverage across `lib/` and `scripts/` |
| `bundle exec rake lint` | Ruby style and packaging checks |
| `bundle exec rake format` | Safe RuboCop corrections |
| `bundle exec rake typecheck` | RBS validation, Steep, and 100% library typed-call coverage |
| `bundle exec rake audit` | Dependency vulnerability audit |
| `bundle exec rake build` | Build the gem in `pkg/` |
| `git diff --check` | Whitespace checks |

Coverage results are not merged with previous runs. Inspect `coverage/index.html` for missing lines or branches. A focused test run can fail the global coverage threshold; run the complete suite before submitting. Typed-call coverage measures the library; the consumer target separately checks that documented workflows type-check.

Pre-commit hooks scan staged changes for secrets, apply and stage safe Ruby formatting fixes, and check whitespace. Commit messages follow Conventional Commits, including `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `perf:`, `build:`, `ci:`, `chore:`, and `revert:`, with optional scope and `!`. Pre-push runs the complete suite. Put local overrides in ignored `lefthook-local.yml`.

## Build and test the package

API reference tables come from shipped RBS signatures and `docs/api_annotations.yml`.
After changing either, regenerate the tables:

```sh
bundle exec ruby -r ./scripts/api_reference -e 'File.write("docs/api.md", APIReference.new(Dir.pwd).render)'
```

The regular test suite checks that generated tables match the public Ruby keywords.

```sh
bundle exec rake build
gem install --local ./pkg/unisender-ruby-0.1.1.gem
```

From outside the checkout, run `ruby -runisender -e 'puts Unisender::VERSION'`. For an isolated check, use a temporary `GEM_HOME` and `GEM_PATH`, and run the examples with a fake transport. The gem includes examples and RBS signatures; development dependencies are not runtime dependencies.

Routine verification must not call a live account, send messages, or change contacts. Live checks require explicit authorization and a designated test account. Publishing and releases are separate maintainer actions.

## Maintainer decisions

Leonid Svyatov is the sole maintainer and decides which changes merge and which versions are released. No successor is arranged if he stops maintaining the project.

Report vulnerabilities privately using [SECURITY.md](SECURITY.md).
