# Repository guidance

## Purpose and scope

`unisender` is a Ruby API client for the service described by the [official UniSender API documentation](https://www.unisender.com/ru/support/category/api/). Use that API family as the source of truth for endpoints, parameters, and responses.

`require "unisender"` exposes the client, named marketing operations, Event Tracking, responses, errors, and optional helpers. Use `docs/api.md` for the implemented surface. Add only the behavior requested for the current task, and keep public examples, RBS signatures, and the Unreleased changelog synchronized with it.

## Working in the repository

1. Read `README.md`, `CONTRIBUTING.md`, `unisender.gemspec`, `Gemfile`, and `Rakefile` before changing setup or tooling. The gemspec defines Ruby compatibility and packaged files; the Gemfile holds development dependencies.
2. Before implementing or changing an API method, read its official method page and the relevant protocol references below. Confirm required parameters, optional parameters, response shape, and documented errors. Keep documentation links near tests or documentation where they explain non-obvious behavior.
3. Prefer test-first changes using the existing Minitest setup. Keep production code under `lib/` and tests under `test/`. Use `Unisender` as the Ruby namespace and retain `require "unisender"` as the public entry point.
4. Run the checks below, then update the README for any new public interface. Report which behavior was observed and which Ruby versions were tested.

Prefer a small dependency surface. Runtime dependencies belong in the gemspec; development dependencies belong in the Gemfile. Verify a dependency against its upstream documentation before adding it.

## API protocol

- Use HTTPS requests to `https://api.unisender.com/{lang}/api/{method}`, where the documented languages are `en` and `ru`. Keep upstream method and parameter names exact on the wire.
- Send API credentials and method parameters in the POST body. Request JSON with `format=json` and encode text as UTF-8. Keep real API keys and contact data out of source, fixtures, logs, exception messages, and inspection output.
- Encode array parameters with the documented bracket syntax, including nested indices where required. Do not assume that the request body is JSON because the response is JSON.
- Check the API response body as well as HTTP status. Successful responses contain `result` and can include `warnings`. Responses with `error` and `code` are failures; ignore any accompanying `result`. Preserve useful upstream error codes and warnings in the public behavior.
- Treat HTTP failures, transport failures, malformed responses, and API errors as distinct cases in tests. Keep requests bounded by timeouts. Add retries only with explicit consideration of whether repeating the method can duplicate a send or mutation.
- Consult current request limits when implementing throttling or retries; limits vary by method. Avoid copying limits into code without tests and a source reference.

### Protocol references

- [Request and response format](https://www.unisender.com/ru/support/api/common/bulk-email/): read when changing authentication, URLs, serialization, or response handling.
- [Connection requirements](https://www.unisender.com/ru/support/api/common/ustanovka-soedineniya-s-api-serverom/): read when changing HTTP or TLS behavior.
- [Array parameters](https://www.unisender.com/ru/support/api/common/sintaksis-massiva-v-argumentah-metodov/): read when a method accepts arrays or nested data.
- [API errors](https://www.unisender.com/ru/support/api/common/api-errors/): read when mapping errors or deciding retry behavior.
- [Request limits](https://www.unisender.com/ru/support/api/common/api-limits/): read when implementing concurrency, throttling, or retries.

## Verification

Install development dependencies with `bundle install`. Run the complete validation suite with `bundle exec rake check` and check whitespace with `git diff --check`. The default Rake task runs the same suite; use `bundle exec rake test` for tests alone. Keep `Gemfile.lock` committed when dependencies change.

Use `bundle exec rake format` for safe RuboCop corrections. Maintain RBS signatures in `sig/` alongside changes to `lib/`; `bundle exec rake typecheck` validates signatures, runs Steep, and enforces 100% typed-call coverage for every library file. Missing analysis, untyped calls, and erroneous calls fail validation. Keep type errors and lint offenses visible rather than adding broad exclusions or untyped signatures to obtain a passing check. Individual tooling commands are listed in the README.

Tests must work offline with fake credentials and deterministic HTTP responses. Cover the request method, URL, encoded body, successful responses, and failure behavior for each implemented operation. Live calls require explicit user authorization and a designated test account; sending messages or changing contacts is not part of routine verification.

The test suite requires 100% line and branch coverage across `lib/` and `scripts/`, including unloaded files. Start SimpleCov before loading project code. Preserve zero-miss thresholds and disabled result merging; cover missing behavior with tests rather than excluding source files or branches. Inspect `coverage/index.html` for failures.

After changes to packaging, dependencies, or the entry point, run `bundle exec rake build`. Install the resulting gem into a temporary gem directory and verify `require "unisender"` from outside the checkout without development dependencies. Keep ad hoc verification scripts and artifacts outside the repository, and remove them when finished.

Do not publish the gem or create a release unless the user requests it.

## Agent skills

### Issue tracker

Issues and specs live in local Markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the seven default canonical triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

Use a single-context layout with `GLOSSARY.md` and `docs/adr/`. See `docs/agents/domain.md`.

### External peers

Reviews use host-only mode without external peer processes. See `docs/agents/cross-model.json`.
