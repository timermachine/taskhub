# Contributing to TaskHub

## Quickest path

Run `tasklab export <task>` in your project. It will:
- Validate no secrets are present
- Show a diff against the current TaskHub version
- Generate a copy-ready PR description or issue body

Then open a PR or issue with that output.

## Standards for merged tasks

- [ ] Run end-to-end at least once — `manifest.yaml` has a `runs` entry with outcome `success`
- [ ] No secrets in any committed file — `tasklab export` checks this automatically
- [ ] `inputs.example.yaml` covers every required variable
- [ ] `01-preflight.sh` validates all required env vars before doing anything
- [ ] `99-run-tests.sh` exits 0 on a correctly configured environment
- [ ] `research.md` has a `verified_on` date within 90 days of submission
- [ ] HITL steps have working `entry_url` links (spot-check before submitting)
- [ ] Task accepts `--project-root <dir>` and writes all runtime artifacts there

## What to contribute

- **New integrations** — a service not yet in TaskHub
- **Updated tasks** — fixed broken links, updated CLI flags, corrected dashboard paths
- **Better HITL steps** — clearer copy-once guidance, more accurate menu paths
- **Improved scripts** — better error messages, additional validations, faster flows
- **New smoke tests** — additional coverage in `99-run-tests.sh`

## Lib/bash changes

Changes to `lib/bash/` affect all tasks. Include in your PR:
- What the change fixes or adds
- Which tasks you tested with the change
- Whether existing function signatures are preserved (breaking changes need a major version bump)

## Not accepted

- Tasks that store secrets in the task folder
- Tasks with hardcoded operator-specific values (use `inputs.example.yaml`)
- Tasks with no end-to-end run evidence
- Docs-only tasks with no runnable scripts or HITL steps
