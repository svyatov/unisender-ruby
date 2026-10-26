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
