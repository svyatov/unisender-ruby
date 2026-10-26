# Rails integration

This example connects a background import, durable recovery state, and an authenticated delivery receiver.
The gem has no Rails dependency. Add it to your application as described in the [README](../README.md).
The example uses Rails 8.1 and a database with transactions and unique indexes.

## Store recovery and delivery state

Add `db/migrate/20261026000000_create_unisender_state.rb`, then run `bin/rails db:migrate`:

<!-- file: db/migrate/20261026000000_create_unisender_state.rb -->
```ruby
class CreateUnisenderState < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs do |t|
      t.json :source, null: false
      t.integer :next_index, null: false, default: 0
      t.json :in_flight
      t.string :status, null: false, default: "ready"
      t.json :diagnostics
    end
    create_table :delivery_events do |t|
      t.string :fingerprint, null: false
      t.string :account, null: false
      t.json :payload, null: false
      t.datetime :processed_at
    end
    add_index :delivery_events, :fingerprint, unique: true
    create_table :email_deliveries do |t|
      t.string :account, null: false
      t.string :email_id, null: false
      t.string :status
      t.datetime :observed_at
    end
    add_index :email_deliveries, [:account, :email_id], unique: true
  end
end
```

Add these models to `app/models`:

<!-- file: app/models/import_run.rb -->
```ruby
class ImportRun < ApplicationRecord
  attr_readonly :source
end
```

<!-- file: app/models/delivery_event.rb -->
```ruby
class DeliveryEvent < ApplicationRecord
end
```

<!-- file: app/models/email_delivery.rb -->
```ruby
class EmailDelivery < ApplicationRecord
end
```

Store source rows as `{"id" => "customer-42", "fields" => {"email" => "person@example.test"}}`.
Keep all row fields consistent. Application IDs remain local; only `fields` are sent.
Do not edit an import's source after creating it.

## Import through an injected client

Add `app/services/import_processor.rb`:

<!-- file: app/services/import_processor.rb -->
```ruby
class ImportProcessor
  def initialize(run, client:)
    @run, @client = run, client
  end

  def call
    while (work = claim)
      batch, offset = work
      @client.import_contacts(records: batch.map { |row| row.fetch("fields") }).raise_for_partial_failure!
      @run.with_lock do
        @run.update!(next_index: offset + batch.size, in_flight: nil, status: "ready")
      end
    end
  rescue Unisender::Error => error
    @run.update!(status: "needs_review", diagnostics: error.diagnostics)
    raise
  end

  private

  def claim
    @run.with_lock do
      raise "Reconcile in-flight rows before resuming" if @run.in_flight.present?
      batch = @run.source.slice(@run.next_index, 500)
      if batch.empty?
        @run.update!(status: "completed")
        nil
      else
        @run.update!(status: "running", in_flight: batch.map { |row| row.fetch("id") })
        [batch, @run.next_index]
      end
    end
  end
end
```

The claim transaction commits before the network call. A crash leaves `in_flight` intact.
A duplicate job cannot send that batch again. A completed batch advances the checkpoint in another transaction.
Never wrap the whole import in a database transaction, because rollback would erase the recovery marker.
Keep each job's source and checkpoints on the primary database, not an eventually consistent replica.

Add `app/jobs/import_contacts_job.rb`:

<!-- file: app/jobs/import_contacts_job.rb -->
```ruby
class ImportContactsJob < ApplicationJob
  def perform(run_id)
    Unisender::Client.open(api_key: Rails.application.credentials.fetch(:unisender_api_key)) do |client|
      ImportProcessor.new(ImportRun.find(run_id), client: client).call
    end
  end
end
```

Start the job from application code with `ImportContactsJob.perform_later(run.id)`.
Use your application's durable Active Job backend. Do not configure automatic mutation retries.
If a backend redelivers a crashed job, the persisted marker stops the remote call.
Reconcile marked rows using the [import recovery procedure](import-recovery.md), then create a separate job for safe remaining work.
`diagnostics` contains safe metadata; `source`, `in_flight`, and response payloads are private application data.

## Authenticate and persist webhook events

Add this route inside `Rails.application.routes.draw` in `config/routes.rb`:

```ruby
match "/unisender", to: "unisender_webhooks#receive", via: [:get, :post]
```

Add `app/controllers/unisender_webhooks_controller.rb`:

<!-- file: app/controllers/unisender_webhooks_controller.rb -->
```ruby
require "unisender/webhooks"

class UnisenderWebhooksController < ActionController::API
  def receive
    return head :ok if request.get?
    notification = Unisender::Webhooks.verify(
      body: request.body.read(1_048_577),
      api_key: Rails.application.credentials.fetch(:unisender_api_key),
      content_encoding: request.get_header("HTTP_CONTENT_ENCODING")
    )
    DeliveryEvent.transaction do
      notification.users.each do |user|
        user.events.each do |event|
          value = [user.login, canonical(event.to_h)]
          fingerprint = Digest::SHA256.hexdigest(JSON.generate(value))
          DeliveryEvent.create_or_find_by!(fingerprint: fingerprint) do |record|
            record.account = user.login
            record.payload = event.to_h
          end
        end
      end
    end
    head :ok
  rescue Unisender::WebhookError
    head :bad_request
  end

  private

  def canonical(value)
    case value
    when Hash then value.sort.to_h.transform_values { |child| canonical(child) }
    when Array then value.map { |child| canonical(child) }
    else value
    end
  end
end
```

GET acknowledges registration only. POST verifies the original body before parsing it into application records.
Set a matching request-body limit in the web server. Return HTTP 200 only after the event transaction commits.
The unique fingerprint suppresses repeated event content, even when a batch is regrouped or object keys change order.
This is an application deduplication rule, not a provider event identifier. Retain the fingerprint for your full replay window.
Serve this endpoint over HTTPS. Exclude webhook bodies from request logging and error-reporting attachments.

Add the payload keys to `config/initializers/filter_parameter_logging.rb`:

```ruby
Rails.application.config.filter_parameters += [:auth, :api_key, :events_by_user]
```

Configure external error and HTTP logging tools separately; Rails parameter filters do not control those tools.

## Process persisted events separately

Add `app/jobs/process_delivery_events_job.rb`:

<!-- file: app/jobs/process_delivery_events_job.rb -->
```ruby
class ProcessDeliveryEventsJob < ApplicationJob
  def perform
    DeliveryEvent.where(processed_at: nil).find_each do |event|
      event.with_lock do
        next if event.processed_at
        apply_status(event)
        event.update!(processed_at: Time.current)
      end
    end
  end

  private

  def apply_status(event)
    payload = event.payload
    return unless payload["event_name"] == "email_status"
    data = payload.fetch("event_data")
    return unless data["email_id"]
    delivery = EmailDelivery.create_or_find_by!(account: event.account, email_id: data.fetch("email_id").to_s)
    observed = Time.find_zone!("UTC").parse(payload.fetch("event_time"))
    delivery.with_lock do
      if delivery.observed_at.nil? || observed > delivery.observed_at
        delivery.update!(status: data.fetch("status"), observed_at: observed)
      end
    end
  end
end
```

Schedule this job periodically through your job backend. It also recovers events persisted before a process crash.
Event processing and the processed marker commit together. Repeated processing does not repeat the state change.
The timestamp guard prevents older notifications from replacing newer status.
This example projects direct-email delivery, using IDs returned by `send_email.accepted_ids`.
Campaign notifications use `campaign_id` and recipient email; add a separate projection when your application needs campaign delivery.
Equal timestamps keep the first observed status. Define a domain-specific precedence if your application needs finer ordering.

Receipt and processing are separate: the receiver persists, then the worker updates application state.
Database failures produce a non-200 response and allow provider redelivery. Authentication failures never create event records.
Signature details and provider limitations are in the [webhook guide](webhooks.md).

## Test without an account

Inject `Unisender::Testing::Transport` into `ImportProcessor` and queue `Fixtures.import_result` responses.
Test complete acceptance, partial acceptance, transport failure, duplicate jobs, and restart from an in-flight marker.
For the receiver, sign synthetic payloads with a fake key. Test invalid auth, duplicate delivery, reordered JSON keys, and older events.
See [testing support](testing.md) for request assertions and [serialization](usage.md#responses-and-failures) for `only:` and `except:`.
