# Receiving UniSender webhooks

Webhook delivery is separate from outbound `track_events`. Register a dedicated HTTPS receiver:

```ruby
client.set_hook(hook_url: "https://example.com/unisender",
                events: { email_status: %w[ok_read ok_link_visited], subscribe: "*" })
client.list_hooks.each { |hook| puts hook.id }
client.remove_hook(hook_url: "https://example.com/unisender")
```

`set_hook` replaces the registration for the same URL. Its defaults are `event_format: :json_post_gzip`, `single_event: false`, and `status: :active`. Mutation methods return raw `Response` payloads because their success fields are not specified. The registration check sends an empty GET and expects HTTP 200. It does not authenticate an event.

Read the request body once, impose a server-side request limit, then verify it before processing:

```ruby
require "unisender/webhooks"

raw = request.body.read(1_048_577)
notification = Unisender::Webhooks.verify(
  body: raw, api_key: credentials.fetch(:unisender_api_key),
  content_encoding: request.get_header("HTTP_CONTENT_ENCODING")
)
notification.users.each do |user|
  user.events.each { |event| persist_event(user.login, event.to_h) }
end
```

The verifier preserves unknown fields and accepts `events` or `Events` within each user, rejecting conflicting keys. It supports only the documented batched JSON format, including gzip. It bounds compressed input, decompressed input, nesting, and event count. Defaults are 1 MiB, 4 MiB, 64 levels, and 10,000 events. It rejects duplicate JSON keys and trailing compressed data. `WebhookError#reason` contains no payload data.

Authentication follows the upstream MD5 procedure on the original decompressed JSON, replacing only the top-level auth value with the JSON-encoded key. Never parse and regenerate the JSON before verification. Authentication alone does not prevent replay. Deduplicate and process events idempotently in durable application storage. Return HTTP 200 only after durable acceptance; keep processing short. Delivery can repeat, and an unsuccessful receiver is retried before registration stops. Handle malformed data without logging bodies, API keys, or contact information.

These contracts are based on [UniSender's webhook documentation](https://www.unisender.com/ru/support/api/common/sistema-uvedomlenij-o-sobytiyah-webhooks/) and offline fixtures. A designated test account and an authorized receiver are still required to verify live delivery.
