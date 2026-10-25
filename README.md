# Unisender

A Ruby client for the [UniSender marketing API](https://www.unisender.com/ru/support/category/api/). Ruby 3.3 or newer, no runtime gem dependencies. This client targets `api.unisender.com`, not UniSender Go.

Explicit keyword methods cover contacts, lists, messages, campaigns, statistics, templates, fields, notes, and Event Tracking. Responses preserve upstream JSON, warnings, and HTTP metadata. See the [API reference](docs/api.md) for the operation index, argument types, and result shapes.

## Install

Add the gem to your application's Gemfile:

```ruby
gem "unisender", "~> 0.1.0"
```

Then run `bundle install`. To install it directly, run `gem install unisender`.

### Install from a checkout

In your application's Gemfile, point to this repository:

```ruby
gem "unisender", path: "../unisender-ruby"
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

The check prints only the HTTP status and list count, including zero for an empty account. Failures exit with status 1. It does not print list names or IDs. The gem itself reads neither environment variables nor `.env`; application code passes the key explicitly.

This example only reads your lists. It does not create contacts or send messages:

<!-- example: examples/quickstart.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
client.get_lists.result.each { |list| puts list.fetch("title") }
```

Save it as `quickstart.rb` and run `bundle exec ruby quickstart.rb`. It prints one title per list, or nothing if the account has no lists. A missing environment variable raises `KeyError` before any request. To try the client without an account or network access, run `bundle exec ruby examples/offline.rb` from this checkout.

## Subscribe a contact

This operation changes your account and normally **sends a confirmation email**. Use an existing list ID from `get_lists`, and an address you control for a manual trial. Set `UNISENDER_LIST_ID` and `UNISENDER_CONTACT_EMAIL` before running it.

<!-- example: examples/subscribe.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
response = client.subscribe(
  list_ids: [ENV.fetch("UNISENDER_LIST_ID")],
  fields: { email: ENV.fetch("UNISENDER_CONTACT_EMAIL") }
)
puts response.result.fetch("person_id")
```

The contact must confirm before receiving campaigns. Use `double_optin: 3` only when you already have consent; it adds the contact without sending the confirmation email. `overwrite: 0` preserves existing fields and tags, `1` replaces them and list membership, and `2` updates supplied fields. See the [upstream subscription rules](https://www.unisender.com/ru/support/api/contacts/subscribe/).

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

Every operation returns `Unisender::Response`: `result`, `warnings`, `data` (the full JSON object), `status`, and `headers`. Values are deeply immutable. JSON keys are strings; numbers are not coerced. Read or copy the data explicitly when your application needs to change it.

Named methods use snake_case and reject unknown keywords. Optional `nil` values are omitted, preserving server defaults. API messages default to English; use `Client.new(api_key: ..., language: :ru)` for Russian. Message-level `lang:` is a separate setting.

```ruby
begin
  client.get_lists
rescue Unisender::APIError => error
  warn error.message
  # Fix credentials, permissions, or parameters using error.code.
rescue Unisender::HTTPError => error
  warn error.message
  # Check error.response.status and error.response.headers.
rescue Unisender::TransportError, Unisender::InvalidResponseError => error
  warn error.message
  # Check service availability before deciding whether to repeat the operation.
end
```

`APIError` also covers API failures returned with HTTP 200; an accompanying result is discarded. `HTTPError` covers non-2xx statuses, including redirects. `InvalidResponseError` covers malformed successful responses. `TimeoutError` is a `TransportError`. All derive from `Unisender::Error`.

Error messages identify known operations and HTTP statuses or documented API codes. Unknown wire method names and unrecognized API codes are not copied into messages. `error.operation` is available separately. Credentials, request bodies, and contact data are omitted. Explicit accessors such as `error.details`, `error.response.data`, and `response.data` can contain private information. No request logging is enabled.

A successful envelope does not mean every recipient succeeded. Inspect `send_email(error_checking: 1, ...)` recipient errors and import counters. A `BatchError` provides `completed_responses`, the zero-based, end-exclusive `failed_range`, and the original `error`. Accepted changes remain applied; do not repeat the whole input automatically. The [batch example](examples/import.rb) shows how to inspect partial results.

## Timeouts, retries, and pagination

```ruby
client = Unisender::Client.new(
  api_key: ENV.fetch("UNISENDER_API_KEY"),
  transport: Unisender::Transport.new(open_timeout: 5, read_timeout: 60, write_timeout: 30),
  retry_policy: Unisender::RetryPolicy.new(max_retries: 2, max_elapsed: 60)
)
```

Those are the default transport timeouts in seconds. TLS certificates are verified, redirects are rejected, and calls do not share connections. **Retries default to zero.** The opt-in policy retries only explicitly identified read-only operations, at most twice, with backoff, jitter, and `Retry-After`. Sends, mutations, imports, exports, events, and unknown methods are never retried automatically. The elapsed retry budget is not a hard request deadline; in-flight requests use transport timeouts.

`each_page` and batch helpers return lazy Enumerators: **consume them to make requests**. Stopping enumeration prevents subsequent requests. `each_page` yields responses, accepts a supported Ruby method name, and raises `PaginationError` at `max_pages`. `wait_for_task` polls an existing job; its deadline is checked between requests. See [helper limits and recovery behavior](docs/api.md#convenience-operations) and [upstream rate limits](https://www.unisender.com/ru/support/api/common/api-limits/).

## Low-level access and types

`client.request("getLists", params: {})` accepts exact upstream names. It handles authentication, encoding, and failures, but does not perform operation-specific conversions. Comma-separated fields must already be strings; nested arrays and hashes become bracketed form fields. Credentials and JSON format cannot be overridden.

RBS signatures ship with the gem. `Response[Result]` describes a named operation's result; the low-level method keeps the general JSON type. Signatures describe documented shapes, not runtime schema validation. Unknown fields remain accessible through `response.data`. Consumer examples are checked with Steep alongside library code.

## Project information

- [Contributing, local checks, and package verification](CONTRIBUTING.md)
- [Changes and compatibility policy](CHANGELOG.md)
- [Source repository](https://github.com/svyatov/unisender-ruby) and [issue reports](https://github.com/svyatov/unisender-ruby/issues)

The repository is currently private; its GitHub links require access. Tests use fake credentials and deterministic responses. They do not establish compatibility with a live account. Released under the [MIT License](LICENSE.txt).
