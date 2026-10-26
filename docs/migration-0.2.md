# Migrating to 0.2

Named operations return typed records and collections. `request` retains raw JSON results.

## Result access

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

`import_contacts_in_batches` and `track_events_in_batches` execute immediately and return a `BatchReport`.
Use `each_import_batch` and `each_event_batch` for lazy execution. Each accepts a block or returns an Enumerator.
Reading a report repeatedly does not repeat requests.

Named paginated reads request 100 items unless you supply `limit`.
Use a fetched page's `each_page` or `auto_each` to continue from that page without refetching it.
Named iterators such as `each_message` yield typed items across pages and accept a block.
Invalid pagination arguments raise when constructing the iterator. HTTP requests remain lazy.
Pagination errors expose `next_offset` and `completed_pages` for recovery.
