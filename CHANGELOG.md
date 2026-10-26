# Changelog

Unreleased collects changes for the next version. Dated sections list user-visible changes, newest first. GitHub release notes reproduce the corresponding section.

## Unreleased

- Separate development installation from published usage and link gem documentation to its version tag.
- Generate API argument and result tables from RBS, with agreement checks for the Ruby interface.

- Expose all documented import counters directly and normalize string-keyed default overrides.
- Validate campaign encoding before creating a message.

- Preserve accepted batches on source exceptions and task context on polling request failures.
- Validate direct pagination controls and include named-result failures in instrumentation.
- Reject special-use download addresses and complete Time signatures for iterators.

- Add opt-in persistent HTTPS connections, lifecycle controls, and shared process-local request pacing.
- Add binary attachment snapshots and a preflighted create-message/send-campaign workflow.
- Add explicit, bounded export downloads without forwarding API credentials.

- Add direct timeout and retry options, environment construction, immutable variants, and message defaults.
- Add safe request instrumentation, structured error categories, recovery hints, and retry-safety checks.
- Ship optional test transport support and application integration guides.
- Expand typed contact, sender-domain, SMS, and campaign-statistics results.

- Expose typed acceptance reports and global batch failure indices without replaying requests.
- Split event batches by encoded bytes and count; preserve completed work when input enumeration fails.

- Accept contact records, named subscription modes, and Ruby time inputs.
- Add task handles with explicit polling, progress callbacks, and contextual timeout errors.

- Execute batch commands immediately; provide explicit lazy batch and typed item iterators.
- Add page navigation with resume offsets and immediate argument validation.

- Return typed immutable records and enumerable collections from named operations.
- Add direct field access, a boolean membership predicate, and singular message results.
- Rename response HTTP metadata to `http_status`; preserve upstream JSON through `data`.

## 0.1.1 - 2026-10-25

- Clarify installation, example destinations, contribution guidance, and maintainer policies.
- Include security, conduct, and release verification documents in the gem.
- Publish signed releases through an approval-gated workflow with an exact-file SPDX inventory and verifiable release assets.

## 0.1.0 - 2026-10-25

- Publish as `unisender-ruby`; load with `require "unisender"` and use the `Unisender` namespace.
- Initial release of the UniSender marketing API client for Ruby 3.3 and newer, with no runtime gem dependencies.
- Add contacts, lists, messages, campaigns, statistics, templates, fields, notes, and Event Tracking operations.
- Add immutable responses, distinct API and transport errors, opt-in read-only retries, pagination, polling, and batch helpers.
- Document local `.env` loading and add a read-only connection check that prints no account data.
- Ignore local `.env` files and clarify the required UTC timestamp format for campaign reads.
- Document checkout installation, read-only onboarding, complete task examples, API argument types, and response contracts.
- Add typed response contracts and consumer example checks.
- Accept the documented top-level success objects from `sendTestEmail` and `updateField`.
- Include known operation names, HTTP statuses, and documented API error codes in safe exception messages.
- Add project metadata, contribution guidance, and standard Conventional Commit types.

## Compatibility policy

Before 1.0, a minor release may change public behavior with migration notes here. Patch releases preserve the documented public interface. After 1.0, releases follow semantic versioning.

The public interface consists of the documented `Unisender::Client`, transport injection contract, responses, errors, retry policy, helpers, and their RBS signatures. Internal modules are implementation details. JSON keys and values preserve upstream representations, including unknown fields; callers must allow for service-side additions. Changes to supported Ruby versions are announced here.

Local fake-response tests do not prove live-account compatibility. Upstream API changes can require a library update even when its Ruby interface is unchanged.
