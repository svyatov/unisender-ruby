# Migrating to 0.2

All changes on this branch remain unreleased. Execution scopes, summary retention, and webhooks are opt-in. `RequestEvent` adds a `request_id` field. Full batch history remains the default; summary mode discards successful payloads and successful row-warning details. See [execution](execution.md) and [webhooks](webhooks.md).

Named operations return typed records and collections. `request` retains raw JSON results.

## Result access

`send_sms` always returns a collection. Replace `response.sms_id` with `response.fetch(0).sms_id` for a single recipient.
Phone arrays are accepted; the raw upstream object or array remains available through `response.data`.

`JSON.generate(response)` serializes the typed payload. Use `response.data` when you need the upstream envelope.
Collections support slices and fetch defaults; object responses provide `to_h`.
`as_json` and `to_json` honor top-level `only:` and `except:` filters and reject unsupported options.
Contact address strings are available through `email_address` and `phone_number`, independent of nested detail shapes.

```ruby
# Before
client.get_lists.result.each { |list| puts list.fetch("title") }
client.create_list(title: "News").result.fetch("id")

# After
client.get_lists.each { |list| puts list.title }
client.create_list(title: "News").id
```

Use `response.result` for the typed result and `response.data` for the original JSON envelope.
Records retain string-key lookup and unknown fields. `to_h` returns a detached mutable copy.
Record equality requires the same concrete class. Use `to_h` when comparing a record with a Hash.
Equivalent records work as Hash keys and in Sets. Object responses also expose `key?`, `keys`, and `values`.

## HTTP metadata

Replace `response.status` with `response.http_status` when reading the HTTP code.
`response.status` exposes a documented result status when the operation supplies one.
Headers and warnings retain their existing names.

## Predicates and singular results

Use `contact_in_lists?` in conditionals. It returns a boolean and accepts `condition: :any` or `:all`.
The response-returning `is_contact_in_lists` method remains available.

`get_message(id:)` returns one message. Empty results raise `NotFoundError`; multiple results raise `InvalidResponseError`.
Count fields use integers. Tabular visited-link results become enumerable records keyed by the returned column names.

## Execution and pagination

Page iterators now execute supplied blocks. Avoid passing a block unless you intend to consume the iterator immediately.
Successful pages expose checkpoint metadata through `offset`, `limit`, and `next_offset`.
Completed task handles return immediately from `wait`; a supplied callback receives the existing handle once.
Failed handles also invoke the callback once, then raise `TaskFailedError` without another request.

`import_contacts_in_batches` and `track_events_in_batches` execute immediately and return a `BatchReport`.
Use `each_import_batch` and `each_event_batch` for lazy execution. Each accepts a block or returns an Enumerator.
Reading a report repeatedly does not repeat requests.

Named paginated reads request 100 items unless you supply `limit`.
Use a fetched page's `each_page` or `auto_each` to continue from that page without refetching it.
Named iterators such as `each_message` yield typed items across pages and accept a block.
Invalid pagination arguments raise when constructing the iterator. HTTP requests remain lazy.
Pagination errors expose `next_offset` and `completed_pages` for recovery. Direct paginated reads now reject invalid limits and offsets before making requests.

## Inputs and tasks

Named methods reject wrong scalar and collection types before a request. Use arrays or comma-separated strings for list IDs and field IDs.
`client.validate!(operation, **arguments)` checks a named request, Event Tracking, or a campaign workflow without networking.
It applies the same defaults and structural rules as execution. Import validation consumes its source; recreate an enumerable before sending.

Campaign `Time` inputs use UTC with `timezone: "UTC"`. Seconds are truncated to the API's minute precision.
Conflicting timezone arguments raise `ValidationError`. String inputs retain their explicit or account-default timezone.

Named flags reject values outside booleans and 0/1 before networking. Known closed choices reject unsupported values.
Library validation failures expose structured fields through `ValidationError`, while remaining rescuable as `ArgumentError`.
`send_email` defaults `error_checking` to true. Use recipient results for IDs; explicit false retains the legacy format.
List/tag arrays in import records become comma-separated scalar cells. Subscription-time arrays retain their list-ID order.

Supply `email:` directly to `subscribe`, or continue using `fields:`.
Subscription modes accept `:request_confirmation`, `:already_confirmed`, and `:confirm_if_needed`.
Overwrite modes accept `:preserve`, `:replace`, and `:update`. Numeric modes retain their meanings.

Imports accept `records:` with consistent keys, including `email`. This input is mutually exclusive with `field_names:` and `data:`.
Record key order may differ; the first record determines column order. Missing columns must be supplied explicitly.
Arrays validate before sending. Streaming input validates as consumed.

Timestamp arguments accept `Time` and convert it to the operation's UTC format. String inputs pass through unchanged.
`ValidationError` provides `field`, `code`, and optional `operation` without including private values.

Export and delivery-report responses are task handles. Call `job.wait` explicitly to poll.
A block passed to `wait` receives each observed state. Polling deadlines retain the last response and task UUID. Request failures during polling preserve their original exception class and add `task_uuid` and `last_response`.

## Partial success

Import, send, and event responses expose `complete?`, `partial?`, `uncertain?`, and `failures`.
These describe request acceptance, not final message delivery. Call `raise_for_partial_failure!` to reject incomplete acceptance explicitly.

`BatchError#report` retains completed responses, known import totals, and failures with global input indices.
Unknown acceptance remains unknown; the client does not count an uncertain request as rejected.
Event batches respect the encoded payload limit as well as the event-count limit.
Streaming input failures retain completed batches. No failed request or input chunk is replayed automatically.

## Configuration and diagnostics

Pass timeout and retry options directly to `Client.new`, or retain explicit transport and policy objects.
Combining an explicit object with its construction options raises `ArgumentError`.
`Client.from_env` reads the API key without loading files. `client.with(...)` leaves the original unchanged.

`message_defaults` supplies sender name, sender email, and message language for message creation and direct email sends.
Explicit arguments override defaults; explicit `nil` suppresses a default.

Use `error.category`, `error.recovery_hint`, and `error.request_id` for diagnosis.
`error.transient?` describes the failure. `error.safe_to_retry?` also checks the operation.
Neither enables retries automatically.

The optional instrumentation callback receives safe metadata for each attempt.
See [application testing](testing.md) for deterministic responses and failure scenarios.

## Optional helpers

Use `persistent: true` for connection reuse and `client.close` when the client is no longer needed.
An injected transport remains caller-owned. Request pacing is opt-in through `rate_limiter:` and is independent of retry settings.


Attachments accept `Attachment.from_path`, `Attachment.from_io`, one attachment, or an array, alongside existing hashes.
`send_campaign(message:, campaign:)` returns both responses and retains a created message if the campaign step fails.
Completed tasks expose `download_to(io, max_bytes:)`. Downloads never happen automatically; errors retain confirmed partial byte counts.
