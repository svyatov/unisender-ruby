# Using the client

## Responses and failures

Named operations return typed responses. Collections support `each`, `map`, and other `Enumerable` methods. Object results expose documented fields directly. `result` contains the typed value; `data` preserves the full upstream JSON object. `http_status`, `headers`, and `warnings` retain response metadata. Values are deeply immutable; use `result.to_h` for a mutable object copy. See [the 0.2 migration guide](migration-0.2.md).

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

A successful envelope does not mean every recipient succeeded. Inspect `send_email(error_checking: 1, ...)` recipient errors and import counters. A `BatchError` provides `completed_responses`, the zero-based, end-exclusive `failed_range`, and the original `error`. Accepted changes remain applied; do not repeat the whole input automatically. The [batch example](../examples/import.rb) shows how to inspect partial results.

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

`each_page` and `each_*` helpers return lazy Enumerators. Consume them, or supply a block to a named iterator, to make requests. Batch command methods execute immediately and return a `BatchReport`. Stopping enumeration prevents subsequent requests. A fetched page exposes `each_page` and `auto_each`; ordinary `each` only visits that page. `each_page` yields responses, accepts a supported Ruby method name, and raises `PaginationError` at `max_pages`. `wait_for_task` polls an existing job; its deadline is checked between requests. See [helper limits and recovery behavior](api.md#convenience-operations) and [upstream rate limits](https://www.unisender.com/ru/support/api/common/api-limits/).

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

See [application testing](testing.md), [Rails integration](rails.md), and the [migration guide](migration-0.2.md).
The [execution guide](execution.md) covers lazy consumption, checkpoints, shared request budgets, cancellation, and summary retention. The [webhook guide](webhooks.md) covers hook management and authenticated receivers. [Staging contract checks](live-contracts.md) are explicitly opt-in.

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

Downloads are explicit, use a separate connection without API credentials, and accept only public HTTPS destinations on port 443. Redirects are rejected. Set a byte limit; `DownloadError#bytes_written` reports confirmed partial output, which remains in your IO. See [helper contracts](api.md#optional-workflow-helpers) for configuration and failure details.
