# Unify direct and paginated operation contracts

Status: D1 selected by the user on 2026-10-25. Ready for implementation; no production changes are part of this plan-writing task.

## Problem

`Pagination::OPERATIONS` repeats wire names and required parameters owned by the named methods. `Pagination#fetch_pages` calls `Client#request` directly, bypassing named-method argument rules. Changing an operation therefore requires coordinated edits, and accepted parameters can diverge.

An offline check confirmed the divergence: `get_messages(..., unexpected: true)` raises `ArgumentError`, while `each_page(:get_messages, ..., unexpected: true).first` sends the unknown parameter. This is information leakage with observable inconsistent validation, not a reason to redesign the whole client.

Source locations at assessment time:

- `lib/unisender/pagination.rb:9`: duplicate operation metadata.
- `lib/unisender/pagination.rb:45`: direct request path.
- `lib/unisender/client.rb:45`: existing named-operation validation path.
- `lib/unisender/operations/statistics_1.rb:25`: representative named method.

## Proposed Interface

Add the internal `Unisender::PaginatedOperations` module in `lib/unisender/paginated_operations.rb`:

```rbs
def self.call: (Client, String | Symbol, params) -> Response
def self.page_limit: (String | Symbol) -> Integer?
```

The module owns a closed, immutable table for exactly these operations:

| Ruby name | Wire name | Required parameters | Maximum page size |
| --- | --- | --- | --- |
| `get_campaigns` | `getCampaigns` | `from` | 10000 |
| `get_messages` | `getMessages` | `date_from`, `date_to` | 100 |
| `list_messages` | `listMessages` | `date_from`, `date_to` | 100 |
| `get_templates` | `getTemplates` | None | 100 |
| `list_templates` | `listTemplates` | None | 100 |
| `get_sender_domain_list` | `getSenderDomainList` | `username` | 100 |
| `get_subscriber_notes` | `getSubscriberNotes` | `subscriber_id` | No documented cap recorded in the existing implementation |

These values describe the current implementation, not a new documentation audit. Before implementing the affected operations, read their official method pages linked beside the existing methods and the protocol references in `AGENTS.md`. Official documentation remains authoritative.

Each table entry also records its permitted keyword symbols. Use the explicit named-method signatures as the current parameter inventory; preserve their optional parameters. Required parameters are also permitted parameters. Keep record representation private; an immutable tuple or small record is an implementation choice, not another public abstraction.

`call` resolves the operation, rejects unknown or non-symbol parameter keys, applies existing required-value and operation validation, and calls `Client#request` with the stored wire name. It returns the original `Response`. Neither error text nor inspection output includes parameter values or credentials. Unsupported operations raise `ArgumentError`.

Named methods retain their Ruby and RBS signatures. For example:

```ruby
def get_messages(date_from:, date_to:, limit: nil, offset: nil)
  params = { date_from:, date_to:, limit:, offset: }
  PaginatedOperations.call(self, :get_messages, params)
end
```

Pagination resolves the page limit through `PaginatedOperations.page_limit`, then requests each page through `PaginatedOperations.call`. Resolution and validation remain inside enumeration, so constructing an enumerator performs no request and raises no argument error. The caller interface remains:

```ruby
client.get_messages(date_from: "2026-01-01", date_to: "2026-01-02")
client.each_page(:get_messages, date_from: "2026-01-01", date_to: "2026-01-02")
```

## Cohesion Statement

Single responsibility: execute a paginated operation through its shared parameter contract.

The new module owns operation lookup, wire names, permitted keywords, required-value validation, and page-size maxima for the seven operations. It shares the existing `Validation` behavior instead of inventing stricter value types.

`Pagination` continues to own lazy enumeration, page-size and page-count checks, initial offset validation, explicit `limit` rejection, offset progression, response counting, grouped sender-domain counting, and termination. Direct calls retain their existing handling of `limit` and `offset`; these pagination controls are intentionally stricter when using `each_page`.

Transport, authentication, form encoding, response parsing, retries, batching, task polling, Event Tracking, and the other 48 named operations remain in their existing modules. `Client#request` remains the low-level escape hatch. Runtime registration and a general operation framework are outside this change.

## Dependency Strategy

UniSender is a true external dependency. Reuse the existing `_Transport` seam, production `Transport`, and test `ScriptedTransport` adapter. The contract table and validation are in-process logic. No new port or injected adapter is necessary.

Use statically typed internal calls with the existing broad `params` type beneath the precise public signatures. Calling named methods through `public_send` or `Method#call` would introduce untyped calls. Adding runtime type restrictions or broadening public RBS signatures would change the agreed contract, so neither is part of D1.

Permitted-key metadata necessarily mirrors explicit Ruby keyword signatures. Test their agreement to detect drift. The shared table removes duplicated wire names and required-value policy from pagination; it does not claim to eliminate the signature declarations Ruby and RBS require.

## Testing Strategy

Exercise the public `Client` interface with fake credentials and `ScriptedTransport`. Retain the existing operation fixture tests, helper tests, and response/error tests. There are no direct tests of a shallow module to delete, so replace only assertions whose expected permissive pagination behavior changes.

Add tests that establish these outcomes:

- Every supported operation produces equivalent method, URL, and encoded parameters through direct and paginated calls when the direct call uses the same `limit` and `offset`.
- Unknown symbol keys and string keys fail with `ArgumentError` before transport. Missing, nil, and empty required values fail in both paths. Required values currently accepted despite being broader than RBS remain accepted at runtime.
- Constructing an enumerator stays lazy, including unsupported operations and invalid arguments. Early stopping causes no additional request.
- All optional keywords remain accepted; a signature-to-contract agreement check catches required/permitted keyword drift across the seven methods.
- Existing page limits, offset progression, final empty pages, grouped-domain counting, malformed-response errors, warnings, upstream errors, and maximum-page termination remain intact.

Tests should verify behavior, not the private table representation. Maintain 100% line and branch coverage across library and scripts, plus 100% typed-call coverage. No live requests are necessary.

## Migration Strategy

Use a single switchover. The public interface stays stable and all affected callers are inside this repository. The intentional behavior change is that `each_page` rejects parameters the named operation rejects, including non-symbol keys that could previously pass through. Document that change in `docs/api.md`; raw `request` retains its existing key handling.

## Implementation Steps

1. Add failing public-interface tests in `test/helpers_test.rb`, `test/helper_boundaries_test.rb`, or one focused test file. Establish parameter parity, lazy failure, accepted optional parameters, and preserved broad runtime values. Finish when the unknown-parameter regression fails for the expected reason and existing behavior checks pass.
2. Add `lib/unisender/paginated_operations.rb` with the two internal entry points and immutable seven-operation metadata. Load it from `lib/unisender.rb`. Add its RBS declarations in `sig/unisender.rbs`. Finish when the module has typed calls and the public signatures remain unchanged.
3. Switch the seven methods in `operations/statistics_1.rb`, `operations/templates_1.rb`, `operations/messages_3.rb`, and `operations/notes_1.rb` to the shared module. Switch `Pagination` to the same path; remove its duplicate wire/required metadata and obsolete signature declarations. Finish when the new parity tests and existing helper tests pass.
4. Update `docs/api.md` to explain shared keyword validation and the intentional distinction between operation parameters and pagination controls. Keep `README.md` examples accurate. Finish when the documentation describes the observed behavior without promising new operation coverage.
5. Run `bundle exec rake check` and `git diff --check` on supported local Ruby versions 3.3.11, 3.4.9, and 4.0.9 through `mise`. Because the entry point changes, install the built gem into a temporary gem directory and verify `require "unisender"`, a named read, and its paginated equivalent from outside the checkout using fake transport. Finish when all gates and package checks pass; remove temporary verification artifacts.
6. Complete QA through the public interface, then review the change against this plan. Finish when the original divergence is fixed, no broader interface change is present, and any review findings are resolved.

Estimated scope: one small library file, seven method-body edits across four files, pagination simplification, entry-point and RBS updates, focused tests, and documentation. Keep the working tree local and uncommitted under the existing user instruction. This plan does not authorize publishing or releases.
