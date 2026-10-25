# Unisender

Ruby gem scaffold for the UniSender API. API methods are not implemented yet.

Requires Ruby 3.3 or newer. There are no runtime dependencies.

## Development

Install the development dependencies and run all checks:

```sh
bundle install
bundle exec rake check
```

The default `bundle exec rake` command runs the same checks: tests, RuboCop, RBS validation, Steep, a dependency vulnerability audit, and the gem build. The audit updates its advisory database and requires network access. CI runs this command on Ruby 3.3, 3.4, and 4.0.

Individual commands:

| Command | Purpose |
| --- | --- |
| `bundle exec rake test` | Run the Minitest suite. |
| `bundle exec rake lint` | Check Ruby style, formatting, performance, tests, and gem packaging. |
| `bundle exec rake format` | Apply safe RuboCop corrections. |
| `bundle exec rake typecheck` | Validate RBS signatures and type-check `lib/` with Steep. |
| `bundle exec rake audit` | Check locked dependencies against current security advisories. |
| `bundle exec rake build` | Build the gem package. |

Keep the signatures in `sig/` synchronized with the library. They are included in the gem for downstream type checking. Development dependencies are locked in `Gemfile.lock`; they are not runtime dependencies of the gem.

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
