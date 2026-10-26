# Rails integration

Construct a client in application-owned code. Pass credentials explicitly and inject the client into services.

```ruby
client = Unisender::Client.new(
  api_key: Rails.application.credentials.fetch(:unisender_api_key),
  read_timeout: 30,
  message_defaults: {
    sender_name: "Example",
    sender_email: "news@example.com"
  }
)
```

Use `client.with` for request-specific configuration. It leaves the original client unchanged.
Explicit call arguments override message defaults. An explicit `nil` suppresses the corresponding default.
Defaults never supply contact lists, recipients, or consent modes.

Run long imports and task polling in background jobs. Keep the source input and completed batch information in application storage.
When a job fails, reconcile accepted records before constructing replacement input.
Do not configure blanket job retries for sends, imports, or event recording.

Inject `Unisender::Testing::Transport` in service tests. The gem does not install Rails hooks or read credentials automatically.
For metrics, pass an `instrumentation` callable receiving `Unisender::RequestEvent`.
It contains operation, attempt, duration, HTTP status, outcome, and error category.
It contains no request payload. Callback failures do not change the API operation's result.
