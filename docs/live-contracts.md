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
