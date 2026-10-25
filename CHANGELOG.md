# Changelog

## Unreleased

## 0.1.0 - 2026-10-25

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
