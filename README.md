# Unisender

This branch documents unreleased 0.2 development. For the published gem, use the [0.1.1 instructions](https://github.com/svyatov/unisender-ruby/blob/v0.1.1/README.md).

A Ruby client for applications using the [UniSender marketing API](https://www.unisender.com/ru/support/category/api/).

Ruby 3.3 or newer, no runtime gem dependencies. This client targets `api.unisender.com`, not UniSender Go.

Explicit keyword methods cover contacts, lists, messages, campaigns, statistics, templates, fields, notes, and Event Tracking. Responses preserve upstream JSON, warnings, and HTTP metadata. See the [API reference](docs/api.md) for the operation index, argument types, and result shapes.

## Install

The following command installs the published 0.1.1 interface. Its usage is documented in the versioned instructions above:

```sh
gem install unisender-ruby
```

For the development interface below, first install from a checkout using the instructions in this section.
Save this read-only example as `quickstart.rb`. It uses the key in `UNISENDER_API_KEY`:

<!-- example: examples/quickstart.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
client.get_lists.each { |list| puts list.title }
# Example output for a list named News: News
```

Run `ruby quickstart.rb`. It prints one title per list, or nothing if the account has no lists. See [Make your first request](#make-your-first-request) for key setup.

After 0.2 is published, a Bundler project can use:

```ruby
gem "unisender-ruby", "~> 0.2.0", require: "unisender"
```

Then run `bundle install`. The package is named `unisender-ruby`; load it with `require "unisender"`.

### Install from a checkout

In your application's Gemfile, point to this repository:

```ruby
gem "unisender-ruby", path: "../unisender-ruby", require: "unisender"
```

Adjust the path, then run `bundle install`. Alternatively, build and install the local package as described in [CONTRIBUTING.md](CONTRIBUTING.md#build-and-test-the-package).

## Make your first request

Get your key from [UniSender's API settings](https://www.unisender.com/ru/support/api/common/api-key/) and put it in the `UNISENDER_API_KEY` environment variable through your shell or application's secret store. Keep it out of source control and logs.

For a local checkout, you can store `UNISENDER_API_KEY=your-key` in `.env`, which Git ignores. Ruby does not load this file automatically. Load your own `.env` into the current shell, then run the read-only connection check:

```sh
set -a
. ./.env
set +a
bundle exec ruby examples/check_connection.rb
```

The check prints only the HTTP status and list count, including zero for an empty account. Failures exit with status 1. It does not print list names or IDs. `Client.new` takes an explicit key. `Client.from_env` reads `UNISENDER_API_KEY`; neither loads `.env`.

The `quickstart.rb` example above only reads lists. It does not create contacts or send messages. In a Bundler project, run it with `bundle exec ruby quickstart.rb`. A missing environment variable raises `KeyError` before any request. To try the client without an account or network access, run `bundle exec ruby examples/offline.rb` from this checkout.

## Subscribe a contact

This operation changes your account and normally **sends a confirmation email**. Use an existing list ID from `get_lists`, and an address you control for a manual trial. Set `UNISENDER_LIST_ID` and `UNISENDER_CONTACT_EMAIL` before running it.

Save the following example as `subscribe.rb`:

<!-- example: examples/subscribe.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
response = client.subscribe(
  list_ids: [ENV.fetch("UNISENDER_LIST_ID")],
  email: ENV.fetch("UNISENDER_CONTACT_EMAIL")
)
puts response.person_id
```

The contact must confirm before receiving campaigns. Use `double_optin: :already_confirmed` only when you already have consent; it adds the contact without sending the confirmation email. `overwrite: :preserve` preserves existing fields and tags, `:replace` replaces them and list membership, and `:update` updates supplied fields. See the [upstream subscription rules](https://www.unisender.com/ru/support/api/contacts/subscribe/).

## Complete workflows

Each example is a standalone Ruby file. Its header lists required environment variables and account effects.

| Task | Example | Effect |
| --- | --- | --- |
| Read lists | [quickstart.rb](examples/quickstart.rb) | Read only |
| Check credentials without printing account data | [check_connection.rb](examples/check_connection.rb) | Read only |
| Test without credentials | [offline.rb](examples/offline.rb) | No network |
| Subscribe a contact | [subscribe.rb](examples/subscribe.rb) | Changes contacts; sends confirmation |
| Create and send a campaign | [campaign.rb](examples/campaign.rb) | Sends to the selected list |
| Export contacts | [export.rb](examples/export.rb) | Starts and polls an export job |
| Import batches with partial-failure handling | [import.rb](examples/import.rb) | Changes contacts |
| Track events with partial-failure handling | [events.rb](examples/events.rb) | Records events; can trigger automation |

## Responses and failures

Named operations return typed responses. Collections support `each`, `map`, and other `Enumerable` methods. Object results expose documented fields directly. `result` contains the typed value; `data` preserves the full upstream JSON object. `http_status`, `headers`, and `warnings` retain response metadata. Values are deeply immutable; use `result.to_h` for a mutable object copy. See [the 0.2 migration guide](docs/migration-0.2.md).

Collections also support `length`, `at`, slices, and `fetch` with a default or block.
`send_sms(phone: [...], sender:, text:)` accepts phone arrays and always returns a receipt collection, including for one phone.
Records provide `key?`, `keys`, `values`, and `fetch` with the same missing-value behavior as a Ruby Hash.
Object responses forward these lookups. Record equality is class-sensitive; use `to_h` to compare with a Hash.
Object responses expose `to_h`. `as_json` and `to_json` serialize the result payload, without HTTP metadata or the response envelope.
Both serializers accept `only:` and `except:` field names. Filters select top-level fields on each record; unsupported options raise `ArgumentError`.
Use `contact.email_address` and `contact.phone_number` for stable address readers; omitted contact details remain `nil`.

Named methods use snake_case and reject unknown keywords. Optional `nil` values are omitted, preserving server defaults. API messages default to English; use `Client.new(api_key: ..., language: :ru)` for Russian. Message-level `lang:` is a separate setting.

Campaign `Time` values use explicit UTC and minute precision. String timestamps retain the specified or account-default timezone.

Library-detected input failures raise `ValidationError`, an `ArgumentError` subclass with `field`, `code`, and `operation`.
Named calls reject incorrect scalar and collection types before networking.
Use `client.validate!(:subscribe, email: "person@example.test", list_ids: [123])` to check arguments and encoding offline.
Validation returns `true` or raises. It applies client defaults and consumes supplied import enumerables, but makes no requests.
Known flags accept only booleans or 0/1. Template types and note ordering also accept documented Symbol choices.
`send_email` requests detailed recipient acceptance by default; set `error_checking: false` for the legacy response or `nil` to omit it.
Use `accepted_ids`, `accepted_recipients`, `rejected_recipients`, and `unknown_recipients` to inspect send outcomes.
`reply_to:` and `priority:` merge with Hash headers; conflicting or multiline values are rejected.
`images_as:` accepts `:attachments`, `:only_links`, or `:user_default` as well as their String forms.

Use this error handler in your application's `request.rb`:

```ruby
begin
  client.get_lists
rescue Unisender::APIError => error
  warn error.message
  # Fix credentials, permissions, or parameters using error.code.
rescue Unisender::HTTPError => error
  warn error.message
  # Check error.response.http_status and error.response.headers.
rescue Unisender::TransportError, Unisender::InvalidResponseError => error
  warn error.message
  # Check service availability before deciding whether to repeat the operation.
end
```

`APIError` also covers API failures returned with HTTP 200; an accompanying result is discarded. `HTTPError` covers non-2xx statuses, including redirects. `InvalidResponseError` covers malformed successful responses. `TimeoutError` is a `TransportError`. All derive from `Unisender::Error`.

Error messages identify known operations and HTTP statuses or documented API codes. Unknown wire method names and unrecognized API codes are not copied into messages. `error.operation` is available separately. Credentials, request bodies, and contact data are omitted. Explicit accessors such as `error.details`, `error.response.data`, and `response.data` can contain private information. No request logging is enabled.

A successful envelope does not mean every recipient succeeded. Inspect `send_email(error_checking: 1, ...)` recipient errors and import counters. A `BatchError` provides `completed_responses`, the zero-based, end-exclusive `failed_range`, and the original `error`. Accepted changes remain applied; do not repeat the whole input automatically. The [batch example](examples/import.rb) shows how to inspect partial results.

## Timeouts, retries, and pagination

In `quickstart.rb`, replace the client construction with:

```ruby
client = Unisender::Client.new(
  api_key: ENV.fetch("UNISENDER_API_KEY"),
  open_timeout: 5, read_timeout: 60, write_timeout: 30,
  max_retries: 2, max_elapsed: 60
)
```

Those are the default transport timeouts in seconds. TLS certificates are verified and redirects are rejected. Connections are separate by default; `persistent: true` enables reuse. **Retries default to zero.** The opt-in policy retries only explicitly identified read-only operations, at most twice, with backoff, jitter, and `Retry-After`. Sends, mutations, imports, exports, events, and unknown methods are never retried automatically. The elapsed retry budget is not a hard request deadline; in-flight requests use transport timeouts.

`each_page` and `each_*` helpers return lazy Enumerators. Consume them, or supply a block to a named iterator, to make requests. Batch command methods execute immediately and return a `BatchReport`. Stopping enumeration prevents subsequent requests. A fetched page exposes `each_page` and `auto_each`; ordinary `each` only visits that page. `each_page` yields responses, accepts a supported Ruby method name, and raises `PaginationError` at `max_pages`. `wait_for_task` polls an existing job; its deadline is checked between requests. See [helper limits and recovery behavior](docs/api.md#convenience-operations) and [upstream rate limits](https://www.unisender.com/ru/support/api/common/api-limits/).

All page iterators accept blocks. Fetched pages expose `offset`, `limit`, and `next_offset` for explicit checkpoints.
Task handles provide `completed?`, `failed?`, and `pending?`. Calling `wait` on a completed handle returns it without another request.
Waiting on a failed handle raises `TaskFailedError` immediately, preserving its response and task UUID.

## Low-level access and types

`client.request("getLists", params: {})` accepts exact upstream names. It handles authentication, encoding, and failures, but does not perform operation-specific conversions. Comma-separated fields must already be strings; nested arrays and hashes become bracketed form fields. Credentials and JSON format cannot be overridden.

RBS signatures ship with the gem. `Response[Result]` describes a named operation's result; the low-level method keeps the general JSON type. Named results validate documented field shapes while retaining unknown fields. Unknown fields remain accessible through `response.data`. Consumer examples are checked with Steep alongside library code.

## Configuration and application tests

`Client.from_env` reads `UNISENDER_API_KEY` from the supplied environment. It does not load `.env`.
Use `client.with(...)` to create an independent configuration variant.
`message_defaults:` accepts only `sender_name`, `sender_email`, and `lang`; explicit call arguments take precedence.

An optional `instrumentation:` callable receives operation, attempt, duration, HTTP status, outcome, error category, and upstream request ID when available.
It receives no request payload. Exceptions raised by the callback do not change the operation's result.

Errors expose `category`, `recovery_hint`, `request_id` when supplied, `transient?`, and `safe_to_retry?`.
Use `error.diagnostics` for a frozen, payload-free Hash with known operation, field, HTTP, and recovery context.
Validation and result-shape failures expose `path`, `expected_type`, `actual_type`, and `documentation_url` when available.
A transient failure does not imply that repeating a mutation is safe.
Import and send reports expose `complete?`, `partial?`, `uncertain?`, and `failures`.
These describe acceptance, not final message delivery.

Imports expose typed `row_warnings` separately from failures and envelope warnings.
The `records:` input accepts arrays in documented list/tag cells and Time values in subscription-time cells.
`unsubscribe(email: ..., list_ids: [...])` and `exclude(phone: ..., list_ids: [...])` provide explicit contact selectors.
`get_contact_count(list_id:, contact_type: :email, search:, tag_id:)` builds filters; the existing `params:` form remains available separately.

See [application testing](docs/testing.md), [Rails integration](docs/rails.md), and the [migration guide](docs/migration-0.2.md).
The [execution guide](docs/execution.md) covers lazy consumption, checkpoints, shared request budgets, cancellation, and summary retention. The [webhook guide](docs/webhooks.md) covers hook management and authenticated receivers. [Staging contract checks](docs/live-contracts.md) are explicitly opt-in.

Use `client.with_execution(timeout: 30, cancellation: token) { |scoped| ... }` for one cooperative budget across related operations. `token` is a `Unisender::CancellationToken`; calling `cancel` stops work at the next boundary. In-flight IO and callbacks are not interrupted.
For large imports, `import_contacts_in_batches(records:, retention: :summary, on_progress:)` returns counts without retaining successful response bodies. Full report retention remains the default.

## Optional workflow helpers

Use connection reuse for repeated calls and close clients when their lifetime ends:

`Unisender::Client.open(api_key: ..., persistent: true) { |client| ... }` closes owned resources when the block exits, including after an exception.
It returns the block's result and never closes an injected transport.

```ruby
client = Unisender::Client.from_env(
  persistent: true,
  rate_limiter: Unisender::RateLimiter.unisender
)
begin
  client.get_lists.each { |list| puts list.title }
ensure
  client.close
end
```

Pacing is opt-in, process-local, and separate from retries. Share a limiter between clients that share an account budget. The built-in preset covers marketing requests; Event Tracking has a separate budget. An injected transport remains caller-owned. Create clients after forking where possible; persistent transports discard inherited connections on a PID change.

Set `event_rate_limiter: Unisender::RateLimiter.new(global: [count, seconds])` to pace Event Tracking independently.
Choose the event budget for your application; the library supplies no provider rate preset for this protocol.

`Attachment.from_path(path)` and `Attachment.from_io(io, filename:)` read binary data into an immutable snapshot. Pass one attachment, an array, or the existing filename-to-bytes hash as `attachments:`. The helper never closes a caller-owned IO.

Pass `max_bytes:` to bound attachment reads. Direct imports inspect at most 501 records; use batching for more than 500 records.

`send_campaign(message: {...}, campaign: {...})` validates both steps before creating the message and returns `receipt.message` and `receipt.campaign`. If campaign creation fails, `CampaignWorkflowError#message_response` preserves the created message. The workflow cannot roll back account changes.

Completed export tasks can stream into a caller-owned IO:

```ruby
completed = client.export_contacts(list_id: 123).wait
File.open("contacts.csv", "wb") do |file|
  completed.download_to(file, max_bytes: 20 * 1024 * 1024)
end
```

Downloads are explicit, use a separate connection without API credentials, and accept only public HTTPS destinations on port 443. Redirects are rejected. Set a byte limit; `DownloadError#bytes_written` reports confirmed partial output, which remains in your IO. See [helper contracts](docs/api.md#optional-workflow-helpers) for configuration and failure details.

## Project information

- [Contributing, local checks, and package verification](CONTRIBUTING.md)
- [Changes and compatibility policy](CHANGELOG.md)
- [Release verification](docs/releases.md)
- [Source repository](https://github.com/svyatov/unisender-ruby) and [issue reports](https://github.com/svyatov/unisender-ruby/issues)

This project is maintained by Leonid Svyatov. Use the public [issue tracker](https://github.com/svyatov/unisender-ruby/issues) for questions and defect reports. Report vulnerabilities privately through [SECURITY.md](SECURITY.md).

Tests use fake credentials and deterministic responses. They do not establish compatibility with a live account. Released under the [MIT License](LICENSE.txt).
