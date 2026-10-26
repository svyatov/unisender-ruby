# Unisender

A Ruby client for applications using the [UniSender marketing API](https://www.unisender.com/ru/support/category/api/).

- Ruby 3.3 or newer, with no runtime gem dependencies.
- Contacts, lists, messages, campaigns, statistics, templates, fields, notes, and Event Tracking.
- Typed immutable results, offline validation, and explicit pagination and batch recovery.
- Targets `api.unisender.com` and Event Tracking, not UniSender Go.

## Install

This branch documents **unreleased 0.2 development**. The published gem is 0.1.1, with [separate instructions](https://github.com/svyatov/unisender-ruby/blob/v0.1.1/README.md).

To use the development interface, add the checkout to your application's `Gemfile`:

```ruby
gem "unisender-ruby", path: "../unisender-ruby", require: "unisender"
```

Adjust the path and run `bundle install`.
For an installed package, follow [build and installation](CONTRIBUTING.md#build-and-test-the-package).
The package name is `unisender-ruby`; the Ruby load path is `unisender`.

## Read your lists

Get your key from [UniSender's API settings](https://www.unisender.com/ru/support/api/common/api-key/).
Set `UNISENDER_API_KEY` through your shell or application's secret store.
The library does not load `.env` files. Keep credentials out of source and logs.

Save this as `quickstart.rb`:

<!-- example: examples/quickstart.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
client.get_lists.each { |list| puts list.title }
# Example output for a list named News: News
```

Run `bundle exec ruby quickstart.rb`. An empty account prints nothing.
To try the client without credentials, run `bundle exec ruby examples/offline.rb` from the checkout.

## Subscribe a contact

This changes your account and normally **sends a confirmation email**.
Set `UNISENDER_LIST_ID` to an existing list and `UNISENDER_CONTACT_EMAIL` to an address you control.
Save this as `subscribe.rb`:

<!-- example: examples/subscribe.rb -->
```ruby
require "unisender"

client = Unisender::Client.new(api_key: ENV.fetch("UNISENDER_API_KEY"))
response = client.subscribe(
  list_ids: [ENV.fetch("UNISENDER_LIST_ID")],
  email: ENV.fetch("UNISENDER_CONTACT_EMAIL")
)
puts response.person_id
```

Run `bundle exec ruby subscribe.rb`. The contact must confirm before receiving campaigns.
Use `double_optin: :already_confirmed` only with consent already established.
To check inputs without networking, call `client.validate!(:subscribe, list_ids: [123], email: "person@example.test")`.

## Handle a failure

Put error handling around calls in your application:

```ruby
begin
  client.get_lists
rescue Unisender::Error => error
  warn error.diagnostics.inspect
end
```

`diagnostics` omits credentials and payloads. Local input errors raise `Unisender::ValidationError`, an `ArgumentError` subclass.
A successful request can still reject recipients. Inspect `complete?`, `partial?`, and `uncertain?` on acceptance reports.
Retries default to zero. Sends and mutations are never automatically retried.

## Find your task

| Task | Guide or example |
| --- | --- |
| Choose an operation or find a keyword | [API reference](docs/api.md) |
| Read results, configure clients, handle errors | [Usage guide](docs/usage.md) |
| Create, inspect, test, and schedule a campaign | [Campaign lifecycle](examples/campaign_lifecycle.rb) |
| Recover an import from durable checkpoints | [Import recovery](docs/import-recovery.md) |
| Export and download contacts | [Export example](examples/export.rb) |
| Record events | [Event example](examples/events.rb) |
| Test an application or configure Cursor | [Testing and editor setup](docs/testing.md) |
| Integrate Rails jobs and delivery webhooks | [Rails guide](docs/rails.md) |
| Control pacing, cancellation, and resource ownership | [Execution guide](docs/execution.md) |
| Upgrade from 0.1 | [Migration guide](docs/migration-0.2.md) |

## Help and project status

Leonid Svyatov maintains this project. Use the public [issue tracker](https://github.com/svyatov/unisender-ruby/issues) for questions and defects.
Report vulnerabilities privately through [SECURITY.md](SECURITY.md).

See [contributing](CONTRIBUTING.md), [changes](CHANGELOG.md), [release verification](docs/releases.md), and the [MIT license](LICENSE.txt).
Tests use fake credentials and deterministic responses. Live account compatibility requires separate [staging checks](docs/live-contracts.md).
