# Unisender

Ruby gem scaffold for the UniSender API. API methods are not implemented yet.

Requires Ruby 3.3 or newer. There are no runtime dependencies.

## Development

Install [Betterleaks](https://github.com/betterleaks/betterleaks) separately and make the `betterleaks` command available on `PATH` (verified with version 1.9.0). Then install the development dependencies and Git hooks, and run all checks:

```sh
bin/setup
bundle exec rake check
```

The default `bundle exec rake` command runs the same checks: tests, RuboCop, RBS validation, Steep, a dependency vulnerability audit, and the gem build. The audit updates its advisory database and requires network access. CI runs this command on Ruby 3.3, 3.4, and 4.0.

Git hooks use Lefthook. Before each commit, Betterleaks scans staged changes for secrets, RuboCop safely corrects and stages matching Ruby files, and Git checks staged whitespace. Commit messages must use `chore: description` or `docs: description`, with an optional scope and breaking-change marker, matching the repository's current commit types. Before each push, the complete `bundle exec rake check` suite runs. Local hook overrides belong in the ignored `lefthook-local.yml` file.

Individual commands:

| Command | Purpose |
| --- | --- |
| `bundle exec rake test` | Run Minitest and require 100% line and branch coverage. |
| `bundle exec rake lint` | Check Ruby style, formatting, performance, tests, and gem packaging. |
| `bundle exec rake format` | Apply safe RuboCop corrections. |
| `bundle exec rake typecheck` | Validate RBS signatures, type-check `lib/`, and require 100% typed calls. |
| `bundle exec rake type_coverage` | Require every library file to be analyzed with zero untyped or erroneous calls. |
| `bundle exec rake audit` | Check locked dependencies against current security advisories. |
| `bundle exec rake build` | Build the gem package. |

Keep the signatures in `sig/` synchronized with the library. They are included in the gem for downstream type checking. Development dependencies are locked in `Gemfile.lock`; they are not runtime dependencies of the gem.

Type coverage is enforced for every Ruby file under `lib/`, including files with no method calls. Missing or failed analysis also fails the check. This measures Steep's typed-call coverage; it is separate from test coverage.

Test coverage includes every Ruby file in `lib/` and `scripts/`, including files the tests never load. Both line and branch coverage must be 100%, with zero uncovered lines or branches. Results from previous runs are not merged. Open `coverage/index.html` to inspect the latest report.

Load the library from this checkout:

```sh
bundle exec ruby -Ilib -runisender -e 'puts Unisender::VERSION'
```

Build the gem:

```sh
bundle exec rake build
```

The package is written to `pkg/unisender-0.1.0.gem`. To install it locally:

```sh
gem install ./pkg/unisender-0.1.0.gem
```

Then load it with `require "unisender"`.

## License

Released under the MIT License. See [LICENSE.txt](LICENSE.txt).
