# Testing application integrations

Load the optional fake transport explicitly. It has no runtime dependencies and never opens a socket.

```ruby
require "unisender/testing"

transport = Unisender::Testing::Transport.new
transport.enqueue(operation: "getLists", data: {
  "result" => [{ "id" => 42, "title" => "News" }]
})
client = Unisender::Client.new(api_key: "test-key", transport:)

raise "Unexpected lists" unless client.get_lists.map(&:id) == [42]
raise "Missing format" unless transport.requests.first.form["format"] == "json"
transport.verify!
```

Each request consumes one queued response. Missing responses and operation mismatches raise immediately.
Call `verify!` at the end of a test to reject unused responses. Mismatch messages contain only recognized operation names.
Use `enqueue(data:, http_status:, headers:)` for API errors, HTTP failures, warnings, and partial results.
Use `enqueue_response` with an `HTTPResponse` for malformed JSON or an exception for transport failures.

Request inspection omits payloads. `form` excludes the API key.
Explicit `body`, `headers`, and `uri` access can expose credentials or contact data. Keep those values out of test failure output.
Queued fixtures should use fake addresses and keys.

## Fixtures and request expectations

`Fixtures.list`, `Fixtures.import_result`, `Fixtures.task`, and `Fixtures.recipient` return result values without the outer `result` envelope.
Required keywords describe the minimum usable fixture; optional keywords add failures, IDs, and download URLs.

Add this expectation to an application test:

```ruby
transport.enqueue(
  operation: "importContacts",
  expected_form: { "field_names[0]" => "email", "data[0][0]" => "person@example.test" },
  data: { "result" => Unisender::Testing::Fixtures.import_result(total: 1) }
)
```

`expected_form:` checks selected encoded fields. `expected_json:` checks nested object subsets and positional array prefixes.
Choose one per reply. Additional request fields are allowed; missing or different expected fields fail immediately.
Error messages contain a redacted field path, without expected or actual payload values. API keys cannot be form expectations.
Use exact request counts and `verify!` when order and extra requests matter.

For Event Tracking, use `transport.requests.last.json` to inspect the decoded JSON payload with its `events` array.
Like `body`, this reader contains contact data. Compare selected fields instead of printing the full payload.

## Type checking in an application

The gem packages RBS under `sig/`, including `sig/manifest.yaml`. With Steep installed in your application's development bundle, use this target in `Steepfile`:

```ruby
target :app do
  check "app"
  library "unisender-ruby"
end
```

Run `bundle exec steep check`. An editor that uses the same Steep project can use these signatures for diagnostics and completion. This repository validates its public consumer examples with Steep; it does not test a specific editor extension.
