# Contributing

This repository is private. Collaborators can use the [issue tracker](https://github.com/svyatov/unisender-ruby/issues). Include the Ruby and gem versions, a minimal example with fake values, expected behavior, and a redacted exception message. Do not post API keys, contact data, export links, or raw request/response bodies.

## Set up

Use Ruby 3.3 or newer and Bundler. CI checks Ruby 3.3, 3.4, and 4.0. Install [Betterleaks](https://github.com/betterleaks/betterleaks) using its upstream installation instructions and ensure `betterleaks` is on `PATH`. Then run:

```sh
bin/setup
bundle exec rake check
```

`bin/setup` installs development dependencies and Lefthook hooks. The complete check runs offline tests, RuboCop, RBS validation, Steep for the library and consumer examples, the dependency vulnerability audit, and the gem build. The audit updates its advisory database and needs network access.

## Make a change

Use a branch such as `fix/error-context` or `feat/new-operation`. Read the official UniSender method documentation before changing a wire contract. Add a regression test with a deterministic transport, keep signatures in `sig/` synchronized, update the relevant docs, and add an entry under Unreleased in [CHANGELOG.md](CHANGELOG.md).

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

```sh
bundle exec rake build
gem install --local ./pkg/unisender-0.1.0.gem
```

From outside the checkout, run `ruby -runisender -e 'puts Unisender::VERSION'`. For an isolated check, use a temporary `GEM_HOME` and `GEM_PATH`, and run the examples with a fake transport. The gem includes examples and RBS signatures; development dependencies are not runtime dependencies.

Routine verification must not call a live account, send messages, or change contacts. Live checks require explicit authorization and a designated test account. Publishing and releases are separate maintainer actions.
