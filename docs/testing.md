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
  library "net-http", "json", "uri", "openssl", "time", "ipaddr", "zlib", "stringio"
end
```

Run `bundle exec steep check`. The gem includes its signatures; copying the library's source into your application is unnecessary.

### Cursor setup

Use [Steep](https://github.com/soutaro/steep) in your development bundle and the publisher's [Steep extension](https://marketplace.visualstudio.com/items?itemName=soutaro.steep-vscode).
The extension repository is [soutaro/steep-vscode](https://github.com/soutaro/steep-vscode).
If Cursor's registry does not list it, download the publisher's VSIX from Visual Studio Marketplace and use **Extensions: Install from VSIX**.

1. Add `gem "steep", group: :development` to your application's Gemfile, then run `bundle install`.
2. Add the `Steepfile` target above, changing `check "app"` to your source directory.
3. Open the project folder in Cursor and run **Steep: Restart** from the command palette.
4. Use **Trigger Suggest** for methods, **Show or Focus Hover** for keywords and return types, and the Problems panel for invalid calls.

The extension launches `bin/steep langserver` when a binstub exists, otherwise `bundle exec steep langserver`.
Ensure Cursor uses the same Ruby and bundle as your terminal. A version-manager shim must resolve Ruby in the project directory.
On macOS, open the canonical folder path, such as `/private/tmp/project` rather than its `/tmp/project` symlink.
Mismatched document paths can hide diagnostics even while the language server runs.

Verified with Cursor 3.27.14, Steep extension 0.10.0, Steep 2.1.0, RBS 4.2.0, and Ruby 4.0.9.
The consumer used an installed 0.2.0 gem outside this checkout.
Observed in the editor: `get_*` completion, `CollectionResponse[List]` hover, required `title: String` keyword help, and rejection of `title: false`.
