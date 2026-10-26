# Consumption, ownership, and recovery

`client.get_lists.each` iterates the fetched response without a network request. An all-page iterator explicitly requests more pages:

```ruby
client.each_message(date_from: "2026-01-01", date_to: "2026-01-02")
      .lazy.map(&:id).take(10).force
```

`map` alone consumes an entire Enumerable immediately. Use `.lazy.map` for early stopping, or `.to_a` when you intend to retain every item. Each new enumeration of a page iterator starts another read sequence. Page offsets do not promise a stable server snapshot.

```ruby
client.each_page(:get_messages, date_from: "2026-01-01", date_to: "2026-01-02") do |page|
  process_page(page)
  save_next_offset(page.next_offset) # Save only after processing succeeds.
end
```

Batch commands such as `import_contacts_in_batches` execute immediately. `each_import_batch` and `each_event_batch` execute when consumed. Re-enumerating them repeats mutations if the source can be replayed. A non-rewindable source may instead be exhausted. Do not use enumeration as a retry mechanism.

The [import example](../examples/import.rb) uses record hashes and reports failed source ranges. Persist the source and reconcile accepted rows before retrying an ambiguous failure. Row indices are zero-based. Do not interpret an HTTP success as complete acceptance or as recipient delivery.

The [export example](../examples/export.rb) saves the task UUID, resumes the saved job, bounds the download, and renames a completed `.part` file. Use private paths on the same filesystem for atomic renames. State persistence and starting a remote job cannot be one atomic transaction: if the process stops before the UUID is stored, reconcile the job before starting another. A partial file contains private contact data and needs the same access controls as the final file.

## Shared request budgets

One `RateLimiter` coordinates clients in one Ruby process. It cannot coordinate worker processes, other applications using the same key, or callers sharing an egress IP. Route those calls through one application-owned request worker or gateway that serializes acquisition against a shared store and accounts for every request. Keep its policy aligned with the [upstream limits](https://www.unisender.com/ru/support/api/common/api-limits/).

Give each worker an explicit client and close it when the worker stops. Inject the client into application services. Do not construct persistent clients before forking. Keep contact data and raw error details out of logs; log the operation, category, and request ID instead.

### Client ownership

| Client or resource | Lifetime and sharing |
| --- | --- |
| Default client | Creates a separate connection for each request; close it when its application owner stops. |
| Persistent client | Serializes requests on its built-in transport. Sharing one client does not increase request concurrency. |
| `client.with(...)` | Creates an independent client lifetime. An injected transport remains shared and caller-owned. |
| `with_execution` client | Borrows its parent's transport and expires when the block ends. Close the parent at its normal lifetime boundary. |
| Injected transports and callbacks | The application supplies any synchronization their implementation needs. |
| Forked worker | Construct clients after forking. Built-in persistent transports discard inherited connections on a PID change. |

Both API protocols send a User-Agent containing the gem and Ruby versions, without account or host information.

## Cooperative execution scopes

```ruby
token = Unisender::CancellationToken.new
client.with_execution(timeout: 30, cancellation: token,
                      instrumentation: ->(event) { record_timing(event.kind, event.duration) }) do |scoped|
  scoped.each_import_batch(records: records) { |response| process_result(response) }
end
# Another thread can call token.cancel.
```

The timeout is one monotonic budget for the scope. Requests, retry delays, pacing, task polling, and batch boundaries use that budget. Nested scopes also obey their parent's deadline and cancellation. The scoped client borrows the parent's transport; closing it does not close the parent. Scoped clients and derived clients cannot be used after the block ends.

Cancellation and deadlines are cooperative. They do not forcibly interrupt an in-flight request, callback, or custom transport. Built-in downloads check between streamed chunks and preserve confirmed bytes in the error. Successful in-flight mutations return their result; the next boundary stops further work. Built-in socket timeouts are reduced to the remaining budget before IO. Do not use this scope as a hard wall-clock timeout. `CancelledError` and `DeadlineExceededError` have separate categories. Batch failures retain completed work, including when cancellation occurs before another batch.

The scope's instrumentation emits payload-free `ExecutionEvent` values for `workflow`, `retry_wait`, `rate_limit_wait`, and `poll_wait`. Existing request instrumentation measures individual network attempts and includes the upstream request ID when available. Observer exceptions do not change the operation's result. Progress callbacks are application work, so their exceptions stop the job with completed-work context.

## Retaining large jobs

Full `BatchReport` history remains the default. For large imports or event streams, select `retention: :summary` on either an immediate or lazy batch helper. Immediate calls return a non-enumerable `BatchSummary`; lazy calls still yield each response but retain no successful response bodies internally.

```ruby
summary = client.import_contacts_in_batches(
  records: records, retention: :summary,
  on_progress: ->(progress) { save_checkpoint(progress.next_index) }
)
puts summary.completed_items
```

`BatchProgress` snapshots contain completed batch and input counts, next source index, invalid count, warning count, and the current `response`. Counts describe completed batches. Summary failures retain the failed response and its row details. Successful warning details and response payloads are discarded, so persist anything you need in the response or progress callback. Retaining progress snapshots also retains their responses. Applications can still retain unbounded data themselves, for example by calling `to_a` on a lazy batch helper.
