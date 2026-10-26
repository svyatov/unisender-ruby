# Recovering imports

Keep source rows and application IDs stable for the whole job. Store them in private application storage.
The [RecoverableImport example](../examples/import_recovery.rb) accepts rows with separate application IDs and API fields.
It persists the source checksum, next completed index, and IDs of the in-flight rows.

Run it from an application file with an injected client:

```ruby
require "unisender"
require_relative "import_recovery"

rows = [
  { "id" => "customer-42", "fields" => { "email" => "person@example.test", "Name" => "Example" } }
]
client = Unisender::Client.from_env
completed = RecoverableImport.new(client, "/private/job-42.json").run(rows)
puts "Completed rows: #{completed}"
```

Use a writable private directory on a filesystem that supports atomic rename. Only one worker may own the checkpoint.
For concurrent workers or transactional guarantees, use a database job row and lock, as in the [Rails integration](rails.md).
Every row must contain the same API field keys. Application IDs are not sent to UniSender.

The example writes intent before sending each batch. It advances the completed index only after complete acceptance.
The response must report zero invalid rows and a total equal to the submitted batch size.
Missing or inconsistent totals preserve the in-flight marker for reconciliation.
A restart with an in-flight marker refuses to send. This covers a timeout, partial response, callback failure, or process crash after sending.

1. Read the persisted application IDs and the original source. Keep the source order unchanged.
2. Inspect `PartialFailure#response` privately for known acceptance and failure details, when available. Row positions are zero-based within that request.
3. Reconcile every in-flight row against the account. A missing response does not prove rejection.
4. Record the reconciliation decision in application storage. Build a separate job for confirmed rejected or unconsumed rows.

Never clear the marker solely because a request failed. A completed batch can already have changed the account.
Source checksums detect accidental edits; they do not provide remote idempotency.
For `BatchError`, `failed_range` identifies source positions, not safe retry input. `error.diagnostics` is safe for logs; raw reports contain contact data.

Application job IDs provide correlation across logs, checkpoints, and manual reconciliation.
For direct email, carry an application reference in documented metadata and retain returned message IDs.
Do not treat `ref_key` as an idempotency guarantee.
