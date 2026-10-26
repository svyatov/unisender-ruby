# Staging contract checks

Offline fixtures establish deterministic behavior. They do not establish the response shapes or permissions of a live account. The repository has not run this harness against an authorized account.

Obtain explicit permission and use a designated test account before running either command. Set `UNISENDER_API_KEY` privately in your environment. Do not save it in a fixture or command transcript.

```sh
UNISENDER_LIVE=1 UNISENDER_LIVE_MODE=read bundle exec ruby -r ./scripts/live_contracts -e 'LiveContracts.run(ENV, $stdout)'
```

Read mode requests lists, fields, and tags. Mutation mode creates one randomly named empty list, reads it back, and deletes that exact list in `ensure`:

```sh
UNISENDER_LIVE=1 UNISENDER_LIVE_MODE=mutation bundle exec ruby -r ./scripts/live_contracts -e 'LiveContracts.run(ENV, $stdout)'
```

Record the date, Ruby version, phase, service environment, and observed contract failures. Keep response bodies private. An interrupted process can leave its created list behind; reconcile that list before rerunning. The harness does not send messages, change contacts, register webhooks, or validate webhook delivery. Those need a separately approved account scenario and receiver.

## Follow-up evidence gates

These scenarios remain pending explicit authorization and a designated test account.
Approve the exact sender, recipients, lists, and receiver before any send or contact mutation.

| Case | Approved action needed | Evidence to retain |
| --- | --- | --- |
| L1 | Run the read-only harness | Successful typed results, HTTP status, tested account environment |
| L2 | Create and delete one empty test list | Exact created ID and confirmed cleanup |
| L3 | Schedule one message with an offset Time | Stored UTC minute, campaign ID, account timezone, final cancellation or completion |
| L4 | Send SMS to one and multiple owned test numbers | Object/array wire cardinality and receipt IDs |
| L5 | Submit a controlled partially invalid email/import batch | Accepted/rejected/unknown counts, warning paths, zero automatic replay |
| L6 | Register a temporary HTTPS receiver and trigger an owned test delivery | Authentication, duplicate handling, status projection, registration cleanup |

Record timestamps and library/Ruby versions. Retain only sanitized findings in this repository.
Keep raw provider responses in private test storage. A green offline suite does not close these gates.
