# Research: paypal/setup-and-integrate

Update these files each run:
- `references/docs.md` — URLs used
- `references/checked-surfaces.yaml` — verified_on + tool versions

## Surface decisions

Execution surface priority: API → CLI → MCP → HITL web

For each HITL step, document why automation was not possible:

| Step | Surface chosen | Reason automation was not possible |
|------|---------------|-------------------------------------|
| Create/select REST app and reveal sandbox credentials | hitl_web | Requires authenticated PayPal Developer Dashboard access and secret reveal/copy action. |
| Verify OAuth token exchange | local_script | Once credentials are in `.env`, `curl` can validate sandbox OAuth without printing secrets. |
| Scaffold Node helper | local_script | Deterministic local file generation in the project root. |

## Notes

- Official docs verified on 2026-04-27:
  - https://developer.paypal.com/api/rest/
  - https://developer.paypal.com/api/rest/authentication/
  - https://developer.paypal.com/api/rest/sandbox/
  - https://developer.paypal.com/studio/checkout/standard/getstarted
- Expected dashboard path: Developer Dashboard > Apps & Credentials > Sandbox > REST API apps.
- Keep secrets out of this file. Record only `.env` path and non-sensitive evidence in reports.
