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
```

Each request consumes one queued response. Missing responses and operation mismatches raise immediately.
Use `enqueue(data:, http_status:, headers:)` for API errors, HTTP failures, warnings, and partial results.
Use `enqueue_response` with an `HTTPResponse` for malformed JSON or an exception for transport failures.

Request inspection omits payloads. `form` excludes the API key.
Explicit `body`, `headers`, and `uri` access can expose credentials or contact data. Keep those values out of test failure output.
Queued fixtures should use fake addresses and keys.
