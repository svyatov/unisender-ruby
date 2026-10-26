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
