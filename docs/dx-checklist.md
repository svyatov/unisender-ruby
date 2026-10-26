# Developer experience implementation

The identifiers refer to the approved five-stage audit. Verification uses offline requests and local TLS fixtures.

| Stage | Items | Status | Evidence |
| --- | --- | --- | --- |
| Typed results | R1, R2, R3, R4, R5 | Complete | Response and record contract tests; typed consumer examples |
| Execution and pagination | E1, E2, E3, E4, E5 | Complete | Execution and iterator contract tests |
| Natural inputs | I1, I2, I3, I4, I5 | Complete | Input and validation boundary tests |
| Workflow outcomes | W1, W2, W3, W4, W5 | Complete | Task handles, report recovery, and event size tests |
| Configuration and diagnosis | C1, C2, C3, C4, C5 | Complete | Configuration, observation, and error category tests |
| Consumer support | D1, D2, D3, D4, D5 | Complete | API reader reference, packaged test support, Rails guide, and migration guide |
| Persistent connections | L1 | Complete | Local TLS reuse and lifecycle tests |
| Request pacing | L2 | Complete | Sliding-window tests |
| Attachments | L3 | Complete | Binary data and ownership tests |
| Campaign workflow | L4 | Complete | Preflight and partial-work tests |
| Export downloads | L5 | Complete | Destination validation and bounded streaming tests |

Each completed stage passed the CI task with full line, branch, and typed-call coverage.
Final acceptance also requires the supported Ruby matrix, isolated gem installation, and host-only review.

## Follow-up audit implementation

This work implements the [2026-10-26 audit](dx-audit-2026-10-26.md) in the approved sequence.

| Phase | Audit items | Status |
| --- | --- | --- |
| P1: reference and installation | DX01, DX02, DX28 | Implemented; generated reference checks pass |
| P2: response ergonomics | DX03, DX09-DX15, DX18, DX20 | Implemented; independent public-interface QA passed |
| P3: validation and outcomes | DX04-DX08, DX16, DX17, DX19 | Implemented; full validation passes |
| P4: consumer support | DX21, DX22, DX26, DX29-DX32 | Implemented; examples, signature discovery, negative input types, and harness guards pass |
| P5: execution and retention | DX23-DX25 | Implemented; independent replay, budget, cancellation, and retention QA passed |
| P6: webhooks | DX27, DX32 | Implemented; independent offline authentication and decoding QA passed |

Publishing and live account operations require separate authorization. Offline evidence does not establish live compatibility.
The staging harness is implemented but has not been run against a live account. DX32's live service validation remains unverified.

Final local validation: 592 tests pass on Ruby 3.3.11, 3.4.9, and 4.0.9. `rake check` passes with 100% line, branch, and typed-call coverage. The built gem loads outside the checkout without development dependencies. Independent QA and host-only review covered the new public behavior; the review's default-documentation and extension-compatibility findings were corrected and rechecked. Mutation probes confirmed that cancellation and authentication tests fail when their checks are disabled.

## Second follow-up implementation

The [second audit](dx-audit-follow-up-2026-10-26.md) is implemented for unreleased 0.2.

| Scope | Items | Evidence |
| --- | --- | --- |
| Input contracts and diagnostics | N01, N02, N03, N11, N12 | UTC scheduling, type validation, bounded input, and preparation-equivalence tests |
| Results and mail | N04, N05, N06, N07, N08, N09, N10 | Serialization, terminal-task, equality, SMS, header, and recipient tests |
| Production integration | N15, N16, N17, N18, N19 | Durable checkpoint example, separate event pacing, safe diagnostics, acceptance accounting, ownership guide |
| Consumer support | N14, N21, N22, N23, N25, N26, N27 | Campaign lifecycle, executable reference calls, exact-package install, Rails and Cursor verification, fixture expectations |

The Rails guide's code ran in a temporary Rails 8.1.4 application with SQLite 2.9.5 and the installed gem.
Six scenarios covered completed/duplicate imports, partial/uncertain recovery, inconsistent counts, Active Job wiring, and authenticated/repeated/out-of-order delivery events.
Cursor 3.27.14 displayed completion, return types, required keywords, and invalid-call diagnostics using the installed gem and Steep.
See [editor setup](testing.md#cursor-setup) for tested versions and the canonical-path requirement.

Final validation passed all 694 tests on Ruby 3.3.11, 3.4.9, and 4.0.9, with 100% line, branch, and typed-call coverage.
`rake check` also passed the dependency audit with no known vulnerabilities.
The built gem passed an isolated installation check, with all 126 packaged files matching the source.
Independent QA and host-only review passed after corrections to uncertain import recovery, alias validation, and nested error paths.

N24 remains a separate [authorized live-account gate](live-contracts.md#follow-up-evidence-gates).
N29 remains a separate [three-developer usability gate](usability-checks.md).
Neither has been run. No "best developer experience" claim is established by the engineering tests.
