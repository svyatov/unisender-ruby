# Developer task validation

The automated suite tests contracts. It does not establish that unfamiliar developers can find and use those contracts.
Use this protocol before claiming superior developer experience.

Recruit three Ruby developers who did not implement the library. Give each the same built gem and documentation revision.
Use fake credentials and `Unisender::Testing::Transport`; live operations require separate authorization.
Do not explain the intended method names or point participants at the answer.

| Task | Completion criterion |
| --- | --- |
| U1: Install and read | Load the installed gem outside its checkout and print a fixture list title. |
| U2: Subscribe | Construct the correct list and email inputs and identify whether confirmation is sent. |
| U3: Recover an import | Preserve completed rows, identify in-flight application IDs, and avoid replaying uncertain rows. |
| U4: Schedule | Create the correct message/campaign sequence and preserve an offset Time in UTC. |
| U5: Receive delivery | Reject an invalid signature, persist a valid event, and avoid processing its duplicate twice. |

For every participant and task, record elapsed time, documentation searches, wrong calls, error interpretation, and requests for help.
The acceptance target is independent completion of each task within ten minutes, without credential disclosure or unsafe replay.
Record incomplete tasks as failures; do not omit them from the timing results.

When multiple participants fail at the same step, compare two concrete interface or documentation revisions with fresh participants.
Keep raw recordings private with participant consent. Publish only consented, anonymized findings.

Status: not run. The engineering changes and offline tests are not a substitute for these observations.
