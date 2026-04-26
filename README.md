# TaskHub

Curated community tasks for [TaskLab](https://github.com/timermachine/TaskLab) — service integration playbooks.

## What's here

```
tasks/        Curated service integration tasks (Stripe, Supabase, Google, Apple, ...)
lib/bash/     Shared bash libraries sourced by task scripts
```

TaskHub is self-contained. Tasks use only the shared libs in `lib/bash/` — no dependency on a specific TaskLab CLI version.

## Using tasks

Install the TaskLab CLI, then run:

```bash
tasklab sync    # pulls latest TaskHub tasks to ~/.tasklab/lib/
tasklab list    # see all available tasks
tasklab run stripe/account/setup-and-integrate
```

TaskLab syncs from this repo automatically before every `tasklab run`.

## Contributing

Found a broken link? Fixed a script? Added a new integration?

1. Run `tasklab export <task>` in your project — it validates, diffs, and generates a contribution-ready summary
2. [Open a PR](https://github.com/timermachine/taskhub/pulls) with your task folder changes
3. Or [open an issue](https://github.com/timermachine/taskhub/issues) and paste the export output

### What makes a good contribution

- Task has been run end-to-end at least once (`manifest.yaml` has a run entry)
- No secrets in any committed file
- `inputs.example.yaml` covers all required values
- `99-run-tests.sh` passes cleanly
- `research.md` has a verified-on date within the last 90 days

## Structure of a task

```
tasks/<service>/<task-name>/
  task.yaml              # goal, scope, inputs, outputs, completion criteria
  plan.yaml              # ordered steps
  manifest.yaml          # maturity + run history
  inputs.example.yaml    # template for operator .env values
  research.md            # surface decisions, docs verified
  hitl/*.step.yaml       # guided manual steps (dashboard/web)
  outputs/scripts/       # numbered shell scripts
  outputs/tests/         # smoke tests
  references/            # docs links, checked-surfaces.yaml
```

## Lib/bash

Shared functions sourced by task scripts. All prefixed `tasklab_*`.

| File | Purpose |
|------|---------|
| `lib/bash/env.sh` | Source env files, precheck for unquoted spaces |
| `lib/bash/task-script.sh` | Clipboard, open URL, require_command, etc. |
| `lib/bash/install.sh` | npm install transparency helper |
| `lib/bash/stripe.sh` | Stripe-specific validation functions |
