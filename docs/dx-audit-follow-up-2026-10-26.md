# Developer experience follow-up audit

Assessed at `e9a16c5` on 2026-10-26. This report proposes changes; it does not implement them or authorize publication.

The library has useful foundations, but its developer experience still has measurable gaps. The highest-value work concerns predictable behavior, diagnosis, and discoverability.

There is no evidence for an absolute "best developer experience" claim. That would require comparative usability testing with developers who did not design the library.

## Scope and evidence

The assessment covered public operations, configuration, results, validation, pagination, tasks, batches, transport, instrumentation, testing support, signatures, examples, and documentation.

`bundle exec rake test` passed on Ruby 4.0.9: 595 runs, zero failures. Eleven additional consumer probes used fake transports and synthetic data. They made no network requests.

Official method documentation and GitHub release metadata were checked separately. No live account requests were made. Other Ruby versions and the full validation suite were not rerun.

The [previous audit](dx-audit-2026-10-26.md) describes an earlier revision. Its [implementation checklist](dx-checklist.md) records the subsequent work. This report avoids proposing those completed features again.

### Capabilities to preserve

| Area | Implemented behavior |
| --- | --- |
| Ruby interface | Explicit keywords, typed records, enumerable collections, natural contact inputs, and RBS signatures |
| Execution | Explicit pagination, task handles, batch reports, cooperative cancellation, and summary retention |
| Reliability | Distinct failure types, conservative retries, optional pacing, and persistent connections |
| Workflows | Attachments, campaign creation, bounded downloads, and webhook verification |
| Integration | Fake transport, runnable examples, Rails guidance, and migration documentation |

Sources: [README](../README.md), [public signatures](../sig/operations.rbs), and [execution guide](execution.md).

### Priority and evidence labels

| Label | Meaning |
| --- | --- |
| P1 | Fix before presenting the development interface as stable |
| P2 | Useful improvement with a concrete caller benefit |
| P3 | Prototype, measure, or establish demand before adding public behavior |
| Observed | Reproduced through the public interface with synthetic data |
| Inspected | Established from source or documentation |
| Proposal | A design opportunity, not a demonstrated defect |
| Proof gap | Required evidence is absent |

## Predictable behavior and diagnosis

### N01. Preserve the instant when scheduling with Time

**P1. Observed. Behavior correction.**

`create_campaign` converts `Time` to UTC text but omits `timezone` unless the caller supplies it. The server interprets omitted timezones through account settings.

The probe supplied `2026-11-01 12:30:00 +03:00`. The request contained `start_time=2026-11-01 09:30:00` without `timezone`.

For `Time` inputs, send explicit UTC and the documented minute format. Preserve intentional String-based account-local scheduling. Define how conflicting timezone arguments are handled.

Add a non-UTC regression case for direct calls and `send_campaign`. The observed request establishes a scheduling risk; no live scheduling error was observed.

Sources: [timestamp conversion](../lib/unisender/inputs.rb), [campaign operation](../lib/unisender/operations/messages_1.rb), and [official scheduling rules](https://www.unisender.com/ru/support/api/messages/createcampaign/).

### N02. Reject wrong scalar types before networking

**P1. Observed. Validation tightening.**

`create_list(title: false)` passes local validation and sends `title=0`. Its public signature requires a String. Other named scalar arguments share the permissive encoder.

Validate documented scalar types at named-operation entry points. Preserve the general encoder for low-level requests. Check configuration containers before invoking methods on them.

Focus on structural correctness. Avoid speculative email rules, account constraints, or restrictions on custom fields. Stricter validation needs compatibility notes.

Sources: [required-value checks](../lib/unisender/validation.rb), [form encoding](../lib/unisender/form.rb), and [signatures](../sig/operations.rbs).

### N03. Identify the exact invalid input or response field

**P1. Observed. Additive diagnostics.**

A nested list value produces `Invalid parameter parameters: invalid_list`. A malformed list record reports only `Invalid result field: id`.

Preserve input paths such as `list_ids[0]` and response paths such as `result[0].id`. Include safe expected and actual type names.

Keep values out of default diagnostics. Add structured fields for programs and a documentation link for humans. Response-shape errors should retain HTTP status and request ID.

Sources: [form diagnostics](../lib/unisender/form.rb), [record validation](../lib/unisender/record.rb), and [error classes](../lib/unisender/errors.rb).

### N04. Honor or reject serialization options explicitly

**P1. Observed. Serialization behavior change.**

`record.as_json(only: [:id])` returns both `id` and `title`. `Record` and `Response` accept an options argument and ignore it.

Support a narrow, documented filtering contract or reject unsupported options. Silent filtering failures can include fields a caller intended to omit.

Check nested records and response wrappers. Keep payload serialization distinct from the raw envelope. Document the selected behavior in the Rails guide.

Sources: [record serialization](../lib/unisender/record.rb), [response serialization](../lib/unisender/response.rb), and [Rails guide](rails.md).

### N05. Treat known failed tasks as terminal

**P2. Observed. Request-count change.**

Completed handles return immediately from `wait`. Failed handles make another status request. A probe with one failed response attempted a second request.

Raise `TaskFailedError` immediately for a known failed handle. Make intentional refresh explicit through `get_task_result` or a documented refresh method.

Define callback behavior for both terminal states. Preserve the failed response and task UUID in the error.

Sources: [task handle](../lib/unisender/task_response.rb) and [task polling](../lib/unisender/task_waiter.rb).

## Ruby interface consistency

### N06. Complete value equality for records

**P2. Observed. Equality behavior change.**

Two records with identical fields compare equal with `==`. They compare unequal with `eql?`, and `Array#uniq` keeps both.

Define a consistent `eql?` and `hash` contract for immutable records. Decide whether different record subclasses can be equal before implementing it.

Verify Array deduplication and Hash-key behavior. Preserve the distinction between value equality and remote-resource identity.

Source: [record equality](../lib/unisender/record.rb).

### N07. Make object-response lookup consistent with record lookup

**P2. Observed. Additive.**

Object responses expose `[]`, `fetch`, `dig`, and `to_h`. Their records also expose `key?`, `keys`, and `values`.

Forward the small read-only lookup interface consistently, or document one canonical route through `result`. A probe confirmed `response.key?` is absent while `response.result.key?` exists.

Avoid forwarding arbitrary methods. HTTP metadata and payload fields must remain distinguishable.

Source: [records and object responses](../lib/unisender/record.rb).

### N08. Provide a uniform SMS receipt path and array input

**P2. Inspected. Additive first.**

`send_sms` accepts a comma-separated String and returns either one receipt or a collection. Callers must encode multiple phones and branch on the result type.

Accept an array of phone strings on the named operation. Provide a stable `receipts` view, or introduce a clearly named multi-recipient helper.

Keep phone numbers as strings. Preserve raw results. A replacement return type would require a migration; an additive receipt view would not.

Sources: [SMS signature](../sig/operations.rbs), [result handling](../lib/unisender/results.rb), and [official SMS contract](https://www.unisender.com/ru/support/api/messages/sendsms/).

### N09. Remove remaining routine wire-value translations

**P2. Inspected. Additive.**

Some choices accept symbols, but options such as `images_as` still require wire strings. Identifier keywords also vary between `id`, `message_id`, and `template_id`.

Add documented symbol mappings where choices are closed. Publish a concise identifier map. Add keyword aliases only where user testing demonstrates repeated mistakes.

Retain the upstream operation names as a useful reference. Do not rename the entire interface for stylistic consistency.

Sources: [named input mappings](../lib/unisender/named_inputs.rb), [operation signatures](../sig/operations.rbs), and [sendEmail options](https://www.unisender.com/ru/support/api/messages/sendemail/).

### N10. Simplify recipient results and common mail headers

**P2. Proposal. Additive.**

Callers filter `recipients` themselves to obtain accepted IDs or rejected recipients. Reply addresses require knowledge of the upstream headers format.

Consider `accepted_recipients`, `rejected_recipients`, and `accepted_ids` as views over the recorded response. Consider explicit `reply_to:` and `priority:` inputs.

These helpers must perform no additional requests. Keep acceptance distinct from delivery, and define conflicts with the existing `headers:` input.

Sources: [recipient results](../lib/unisender/outcomes.rb) and [documented mail headers](https://www.unisender.com/ru/support/api/messages/sendemail/).

## Imports and workflow convenience

### N11. Bound direct-import validation and attachment reads

**P1. Observed for imports; inspected for attachments. Resource behavior change.**

Direct `import_contacts(records:)` materializes the source before enforcing the 500-row limit. A 600-row probe consumed all 600 rows before raising, without sending anything.

Stop direct-import consumption when the first excess row is found. Point the error at `import_contacts_in_batches`. Keep batch helpers suitable for larger sources.

Consider an explicit byte limit for `Attachment.from_io` and `from_path`; both read the complete input. Do not silently switch to streaming multipart requests.

Sources: [direct import](../lib/unisender/operations/contacts_2.rb), [record consumption](../lib/unisender/record_rows.rb), and [attachments](../lib/unisender/attachment.rb).

### N12. Expose an offline validation or preparation path

**P2. Proposal. New public interface.**

Applications cannot directly ask whether an operation passes local validation without constructing a fake request path. Campaign workflows already perform private preflight checks.

Consider one preparation interface that returns normalized, redacted metadata and structured validation errors. It must reuse the execution path's validation.

Describe it as local validation, not server approval. It cannot prove consent, sender verification, account balance, or deliverability. Avoid exposing credentials in prepared requests.

Sources: [operation preparation](../lib/unisender/client.rb) and [campaign preflight](../lib/unisender/campaign_workflow.rb).

### N13. Offer explicit column mapping for heterogeneous input

**P3. Inspected. New import option.**

`records:` requires every row to contain the same columns. Model exports and CSV inputs often need repeated key mapping and missing-value handling.

Prototype an explicit column schema or documented mapping recipe. Preserve the difference between an absent value, an empty value, and an intentional replacement.

Keep strict matching as the default. Establish upstream update semantics before adding automatic padding or coercion.

Sources: [column validation](../lib/unisender/record_rows.rb), [cell conversion](../lib/unisender/import_cells.rb), and [import example](../examples/import.rb).

### N14. Provide a reviewable campaign lifecycle example

**P2. Proposal. Documentation first.**

`send_campaign` covers creation and launch. Add one complete example for create, inspect, test-send, schedule, and observe status.

Make every network effect explicit. Include the correct identifier at each step and explain where account-side verification can fail.

Only add a workflow object after the example reveals repeated application code. A status waiter must never create another campaign.

Sources: [campaign helper](../lib/unisender/campaign_workflow.rb), [message methods](../lib/unisender/operations/messages_2.rb), and [statistics methods](../lib/unisender/operations/statistics_1.rb).

### N15. Make batch recovery actionable without implying replay safety

**P2. Proposal. Additive views and examples.**

Reports preserve completed work and failed ranges. Applications still reconstruct source rows and decide how to handle rejected, accepted, and unknown outcomes.

Provide an example with stable application row identifiers and persisted checkpoints. Consider explicit views for known rejections, unknown outcomes, and unconsumed input.

Do not equate a failed range with safe retry input. The failed batch can contain accepted changes. Keep automatic mutation replay disabled.

Sources: [batch reports](../lib/unisender/batch_report.rb), [batch execution](../lib/unisender/batches.rb), and [recovery guide](execution.md).

## Production integration

### N16. Make pacing cover both protocols explicitly

**P2. Inspected. Opt-in extension.**

The configured rate limiter is deliberately bypassed for `track_events`. Developers need another mechanism to pace event batches.

Offer a separate event budget or a documented protocol-aware limiter contract. Show how an application coordinates multiple processes and shared credentials.

Verify provider limits before implementing a preset. Preserve separate marketing and event budgets. Distributed storage should remain application-owned.

Sources: [limiter dispatch](../lib/unisender/request_execution.rb), [limiter](../lib/unisender/rate_limiter.rb), and [execution guide](execution.md).

### N17. Observe acceptance separately from successful requests

**P2. Observed. Additive instrumentation.**

A send with every recipient rejected emits `outcome: :success` and no error category. This correctly describes decoding, but cannot measure accepted sends.

Add a separate acceptance observation containing known counts and uncertainty. Retain request-attempt metrics with their existing meaning.

Include successful import warnings and partial acceptance in examples. Keep recipient addresses and message content out of telemetry.

Sources: [request observation](../lib/unisender/observation.rb), [request execution](../lib/unisender/request_execution.rb), and [acceptance reports](../lib/unisender/outcomes.rb).

### N18. Provide a safe diagnostic record and correlation recipe

**P2. Proposal. Additive.**

Applications assemble log fields from different errors and wrappers. Request and workflow instrumentation also use separate event types.

Provide one documented diagnostic projection with operation, category, request ID, task UUID, and known progress. Include only available fields.

Document application-owned correlation IDs across sends, jobs, and webhooks. Do not claim `ref_key` guarantees idempotency without verifying that contract.

Sources: [errors](../lib/unisender/errors.rb), [error diagnostics](../lib/unisender/error_diagnostics.rb), [execution context](../lib/unisender/execution_context.rb), and [sendEmail reference key](https://www.unisender.com/ru/support/api/messages/sendemail/).

### N19. Make client identity and ownership easy to diagnose

**P2. Inspected. Headers and documentation.**

The client does not set its gem version in a User-Agent header. Persistent clients serialize requests, and configuration variants have resource ownership rules.

Add a stable library User-Agent without credentials or host-specific details. Document thread sharing, fork creation, derived-client closure, and injected-transport ownership in one table.

Add a concurrent worker example only after verifying its actual lifecycle. Do not promise increased throughput from sharing one serialized persistent client.

Sources: [request headers](../lib/unisender/request_execution.rb), [persistent transport](../lib/unisender/persistent_transport.rb), and [configuration variants](../lib/unisender/client_configuration.rb).

### N20. Measure copying and retention with realistic data

**P3. Inspected design; performance unmeasured.**

Responses retain raw envelopes and typed results. Several typed readers construct fresh records or arrays on each call. Large inputs also incur encoding copies.

Benchmark representative imports, exports, attachments, and repeated result access. Measure peak memory, allocations, and elapsed time before changing implementation.

Consider normalizing nested typed records once. Preserve immutable public values and raw-response access. Summary retention already exists and should remain available.

Sources: [responses](../lib/unisender/response.rb), [contact readers](../lib/unisender/contact_records.rb), [outcome readers](../lib/unisender/outcomes.rb), and [summary retention](../lib/unisender/batch_summary.rb).

## Documentation and release usability

### N21. Reduce the first-use reading burden

**P2. Inspected. Documentation restructuring.**

The README combines installation, core usage, transport policy, advanced execution, and optional workflows. Most details already have dedicated guides.

Keep the first page focused on installation, one successful request, one mutation, one failure, and task navigation. Move detailed contracts to linked guides.

Show released and development installation paths clearly. Preserve the gem-name and require-path explanation; that distinction is intentional.

Sources: [README](../README.md) and [versioned published instructions](https://github.com/svyatov/unisender-ruby/blob/v0.1.1/README.md).

### N22. Add task navigation and operational facts to the reference

**P2. Inspected. Documentation and generated metadata.**

The generated reference lists arguments and results. Add task-oriented entry points and concise facts about effects, local versus network work, pagination, and recovery.

Give each common operation a minimal Ruby example. Explain `get_messages` versus `list_messages`, response versus record access, and each identifier's origin.

Extend agreement checks to these facts where they are executable. Avoid generating business explanations from method names alone.

Sources: [API reference](api.md), [reference generator](../scripts/api_reference.rb), and [annotations](api_annotations.yml).

### N23. Verify the exact installation path and remove stale artifact names

**P1. Inspected and release metadata checked. Documentation correction and release gate.**

The checkout declares 0.2.0, but CONTRIBUTING installs `unisender-ruby-0.1.1.gem` after building. A developer can install a stale artifact or encounter a missing file.

Derive the artifact name from the version. Test installation and copied examples outside the repository using the exact built package.

GitHub's latest release remained `v0.1.1` during this audit. Keep development instructions separate until publication is authorized; packaging a feature does not make it available.

Sources: [build instructions](../CONTRIBUTING.md), [version](../lib/unisender/version.rb), and [published release](https://github.com/svyatov/unisender-ruby/releases/tag/v0.1.1).

### N24. Close the live-contract evidence gap

**P1. Proof gap carried from the previous audit. Authorized staging work.**

The staging harness exists, but its checklist states it has not been run against a live account. Fake responses cannot establish provider compatibility.

Run the documented read-only and mutation phases only with explicit authorization and a designated test account. Record tested service behavior and sanitized discrepancies.

Prioritize scheduling, response cardinality, partial acceptance, and webhook payloads. Keep destructive or sending probes individually scoped. This audit did not use local credentials.

Sources: [contract guide](live-contracts.md), [staging harness](../scripts/live_contracts.rb), and [implementation evidence](dx-checklist.md).

### N25. Provide one complete application integration

**P2. Inspected. Example application work.**

The Rails guide covers construction and general advice. It does not demonstrate a complete background job, persisted recovery, and authenticated webhook receiver together.

Provide a small runnable integration with injected clients, application-owned checkpoints, and typed outcomes. Show how final delivery updates application state.

Separate receipt of a webhook from duplicate processing. Explain which retry decisions belong to the job and which belong to the client.

Sources: [Rails guide](rails.md), [webhook guide](webhooks.md), and [execution guide](execution.md).

## Development tools and evidence of usability

### N26. Verify editor completion from an installed consumer project

**P2. Proof gap. Consumer verification.**

RBS discovery and Steep consumer checks exist. The testing guide explicitly does not claim verification of a particular editor integration.

Verify completion, keyword help, return types, and invalid-call diagnostics in one supported editor setup. Use the installed gem outside this checkout.

Document the exact setup and tested versions. Keep editor extensions and alternative type systems optional; do not add signature formats without user demand.

Sources: [typing guide](testing.md), [signature manifest](../sig/manifest.yaml), and [consumer examples](../test/consumer/ergonomics.rb).

### N27. Reduce fixture boilerplate without concealing protocol errors

**P2. Proposal. Optional testing support.**

The fake transport supplies deterministic queued responses and verifies consumption. Applications still construct wire-shaped success, partial-failure, and task fixtures themselves.

Consider small documented fixture builders for common result shapes. Add request assertions that explain safe differences in operation, selected fields, and order.

Keep raw response enqueueing available for malformed-response tests. Helpers must not make incorrect requests look successful by accepting every parameter shape.

Source: [testing support](../lib/unisender/testing.rb) and [testing guide](testing.md).

### N28. Offer a bounded diagnostic command if users need it

**P3. Proposal. Optional executable.**

The read-only connection example is useful but requires locating a checkout file. An installed diagnostic command could reduce support setup.

Prototype local checks for gem version, Ruby version, and credential presence. Make a network credential check explicit and read-only.

Report safe structured output and exit codes. Do not add a general account-management CLI or print credentials and contact data.

Source: [connection example](../examples/check_connection.rb).

### N29. Test developer tasks, not only library contracts

**P1 for validating a quality claim. Proof gap. Research activity.**

The suite measures specified behavior. It does not measure whether an unfamiliar developer can discover the correct workflow or recover from failure.

Observe developers completing installation, subscription, partial-import recovery, scheduling, and webhook integration. Record time, documentation searches, wrong calls, and unrecovered errors.

Compare at least two interface or documentation designs for tasks with repeated failures. Set measurable acceptance criteria before claiming superior developer experience.

Sources: [consumer tests](../test/consumer/quickstart.rb) and [workflow examples](../examples).

### N30. Prototype resource grouping only after measuring discovery problems

**P3. Proposal. Potentially large interface expansion.**

The client exposes many flat named methods. Resource grouping could improve completion and navigation, but a second complete interface adds learning and maintenance costs.

Test a small `contacts` or `messages` prototype against the flat interface. Compare task completion and mistakes before expanding it.

Prefer better documentation navigation if it solves discovery. Keep explicit network effects, typed methods, and a low-level escape hatch in either design.

Sources: [public operations](../sig/operations.rbs) and [previous design deferrals](dx-audit-2026-10-26.md#design-choices-to-defer).

## Findings that should not become changes

| Candidate | Reason |
| --- | --- |
| Allow filter-free `get_contact_count(list_id:)` | The probe raises, but the official contract requires at least one filter. This is correct behavior. |
| Add implicit pagination to ordinary `each` | Fetching more pages changes effects and costs. Explicit all-page helpers already exist. |
| Automatically replay failed sends or imports | An ambiguous failure can follow accepted changes. Better recovery views do not establish replay safety. |
| Replace the package name or load path | `unisender-ruby` and `require "unisender"` are intentional compatibility choices. |
| Add global configuration or mandatory framework dependencies | Application-owned clients and optional integration keep scope and testing predictable. |

Source for count-filter behavior: [official getContactCount contract](https://www.unisender.com/ru/support/api/contacts/getcontactcount/).

## Suggested delivery sequence

1. Correct scheduling, validation, serialization options, and bounded direct-import consumption: N01, N02, N03, N04, and N11.
2. Complete focused Ruby contracts and business-outcome telemetry: N05, N06, N07, N08, and N17.
3. Simplify documentation and verify the built consumer artifact: N21, N22, N23, N25, and N26.
4. Obtain authorized live-contract evidence and measure developer task completion: N24 and N29.
5. Select remaining additions from repeated application work and measured demand, keeping P3 designs as experiments.

Each behavior change needs a focused consumer regression test, synchronized signatures, and migration notes when compatibility changes.

Publication, new dependencies, and live account actions remain separate decisions. This report changes no library behavior.
