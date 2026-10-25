# Unisender

A Ruby client for the UniSender marketing API, with explicit methods for all documented operations, Event Tracking, asynchronous jobs, and opt-in convenience helpers. Requires Ruby 3.3 or newer and has no runtime gem dependencies.

See the [complete API reference](docs/api.md) for supported methods, parameters, protocol decisions, and helper behavior. This is the marketing API at `api.unisender.com`, not UniSender Go.

## Usage

Add `gem "unisender"` to your Gemfile and run `bundle install`.

```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
lists = client.get_lists
lists.result.each { |list| puts list.fetch("title") }

response = client.create_list(title: "Product news")
list_id = response.result.fetch("id")
client.subscribe(list_ids: [list_id], fields: { email: "person@example.com" })
```

The subscription example uses UniSender's default confirmation behavior. Set `double_optin: 3` only when you already have the contact's consent. Named methods use snake_case, explicit keyword arguments, and the upstream parameter names. Unknown keywords fail immediately. API messages default to English; use `language: :ru` for Russian. Message-level `lang:` remains a separate parameter.

## Responses and errors

Every operation returns a `Response` with `result`, `warnings`, `data` (the full JSON object), `status`, and `headers`. The response and its contents are immutable. JSON keys remain strings, unknown fields are preserved, and numeric values are not coerced.

```ruby
begin
  response = client.create_email_message(
    sender_name: "Example", sender_email: "news@example.com",
    list_id: list_id, subject: "Product news", body: "<p>Hello</p>"
  )
  client.create_campaign(message_id: response.result.fetch("message_id"))
rescue Unisender::APIError => error
  # The upstream code is accessible separately from the safe exception message.
  handle_api_error(error.code)
rescue Unisender::HTTPError, Unisender::TransportError => error
  handle_delivery_failure(error)
end
```

`APIError` identifies an API error even when HTTP status is 200. Any accompanying result is discarded. `HTTPError` identifies unsuccessful HTTP responses, including redirects; `InvalidResponseError` identifies malformed successful responses. `TimeoutError` is a `TransportError` subtype. All derive from `Unisender::Error`.

Exceptions and inspection output omit credentials and contact data. Explicit accessors such as `APIError#details`, `Response#data`, and `EventError#details` can contain private data returned by the service. No request logging is enabled.

A successful HTTP/API envelope does not guarantee every recipient or record succeeded. Inspect the per-recipient `errors` returned by `send_email(error_checking: 1, ...)` and the counters and `log` from `import_contacts`.

## Timeouts and retries

```ruby
client = Unisender::Client.new(
  api_key: ENV.fetch("UNISENDER_API_KEY"),
  transport: Unisender::Transport.new(open_timeout: 5, read_timeout: 60, write_timeout: 30),
  retry_policy: Unisender::RetryPolicy.new(max_retries: 2, max_elapsed: 60)
)
```

These are the default transport timeouts in seconds. TLS certificate verification is enabled. Connections are not shared between calls, and redirects are not followed.

Retries default to zero. The opt-in policy permits at most two retries of explicitly identified read-only methods, using exponential backoff, jitter, and `Retry-After`. Waits over 30 seconds or outside the elapsed budget stop retrying. Sends, mutations, imports, export creation, event batches, and unknown methods are never retried automatically. The client does not impose a global rate limiter; follow the [upstream account and method limits](https://www.unisender.com/ru/support/api/common/api-limits/).

## Pagination, batches, and asynchronous jobs

```ruby
client.each_page(:get_campaigns, from: "2026-01-01 00:00:00").each do |page|
  process_campaigns(page.result)
end

client.import_contacts_in_batches(
  field_names: %w[email Name],
  data: [["person@example.com", "Example"]]
).each { |batch| process_import_result(batch.result) }

job = client.export_contacts(list_id: list_id)
completed = client.wait_for_task(task_uuid: job.result.fetch("task_uuid"))
download_url = completed.result.fetch("file_to_download")
```

Enumerators make requests only as they are consumed. Batch errors expose earlier successful responses and the affected input range; see the [helper reference](docs/api.md#convenience-operations). Stopping an Enumerator stops subsequent requests. Data already accepted by UniSender remains accepted.

## Event Tracking

```ruby
client.track_events(events: [
  { name: "purchase", email: "person@example.com", total: 1200, currency: "RUB" }
])
```

Event Tracking uses a separate JSON endpoint and bearer authentication. A successful response has `result == { "success" => true }`. `EventError` exposes `code`, `details`, and `possibly_partially_accepted?`. HTTP 400 can mean that valid events were accepted while others failed. Never retry the entire batch without checking that outcome. For larger inputs, use `track_events_in_batches(events: enumerable)`.

## Low-level access and testing

```ruby
response = client.request("getLists", params: {})
```

The low-level method retains exact upstream names and uses the same encoding, response handling, and retry policy. Credentials and JSON format cannot be overridden. Nested hashes and arrays become bracketed form fields; comma-separated fields must already be strings when using this method.

A custom transport can be injected for offline tests. It implements `post(uri, headers:, body:)` and returns `Unisender::HTTPResponse.new(status:, headers:, body:)`. Header keys in returned responses should be lowercase. The built-in transport handles this normalization.

## Development

Install [Betterleaks](https://github.com/betterleaks/betterleaks) separately and make the `betterleaks` command available on `PATH` (verified with version 1.9.0). Then install the development dependencies and Git hooks, and run all checks:

```sh
bin/setup
bundle exec rake check
```

The default `bundle exec rake` command runs the same checks: tests, RuboCop, RBS validation, Steep, a dependency vulnerability audit, and the gem build. The audit updates its advisory database and requires network access. CI runs this command on Ruby 3.3, 3.4, and 4.0.

Validated locally on Ruby 3.3.11, 3.4.9, and 4.0.9 with 258 offline tests, 100% line and branch coverage, and 100% typed-call coverage. Standalone installed-gem workflows also pass on all three versions. No live UniSender account calls are included in this validation.

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
