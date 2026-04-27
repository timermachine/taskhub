#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="."
ENV_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat >&2 <<'EOF'
Usage:
  02-scaffold-node-paypal.sh --project-root <dir> [--env-file <path>]

Creates a minimal Node.js PayPal Orders API helper under:
  <project-root>/paypal-integration/
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="${2:-}"; shift 2 ;;
    --env-file)     ENV_FILE="${2:-}"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unexpected argument: $1" >&2; usage; exit 2 ;;
  esac
done

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_lib/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_lib/git.sh"
ENV_FILE="$(tasklab_script_default_env_file "$PROJECT_ROOT" "$ENV_FILE")"
tasklab_env_source_file "$ENV_FILE"

tasklab_env_need "$ENV_FILE" "PAYPAL_ENVIRONMENT"
tasklab_env_need "$ENV_FILE" "PAYPAL_CLIENT_ID"
tasklab_env_need "$ENV_FILE" "PAYPAL_CLIENT_SECRET"

if [[ "${PAYPAL_ENVIRONMENT:-}" != "sandbox" ]]; then
  echo "Refusing to scaffold against non-sandbox PayPal environment." >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/paypal-integration"

cat > "$PROJECT_ROOT/paypal-integration/package.json" <<'EOF'
{
  "name": "paypal-integration",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node test.mjs",
    "test:oauth": "node smoke-token.mjs",
    "create-order": "node create-order.example.mjs"
  },
  "engines": {
    "node": ">=18"
  }
}
EOF

cat > "$PROJECT_ROOT/paypal-integration/load-env.mjs" <<'EOF'
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const envPath = process.env.TASKLAB_ENV_FILE || resolve(here, '..', '.env');

if (existsSync(envPath)) {
  const lines = readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!match) continue;

    const [, key, rawValue] = match;
    if (process.env[key] !== undefined) continue;

    let value = rawValue.trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    process.env[key] = value;
  }
}
EOF

cat > "$PROJECT_ROOT/paypal-integration/paypal-client.mjs" <<'EOF'
const PAYPAL_ENVIRONMENT = process.env.PAYPAL_ENVIRONMENT || 'sandbox';

if (PAYPAL_ENVIRONMENT !== 'sandbox') {
  throw new Error('This sample is configured for sandbox use only.');
}

const API_BASE = 'https://api-m.sandbox.paypal.com';

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export async function getPayPalAccessToken() {
  const clientId = requiredEnv('PAYPAL_CLIENT_ID');
  const clientSecret = requiredEnv('PAYPAL_CLIENT_SECRET');
  const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const response = await fetch(`${API_BASE}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${basicAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`PayPal OAuth failed with HTTP ${response.status}: ${body}`);
  }

  return response.json();
}

export async function createOrder({
  amount = process.env.PAYPAL_TEST_AMOUNT || '1.00',
  currency = process.env.PAYPAL_CURRENCY || 'USD',
} = {}) {
  const token = await getPayPalAccessToken();
  const response = await fetch(`${API_BASE}/v2/checkout/orders`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [
        {
          amount: {
            currency_code: currency,
            value: amount,
          },
        },
      ],
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`PayPal create order failed with HTTP ${response.status}: ${body}`);
  }

  return response.json();
}
EOF

cat > "$PROJECT_ROOT/paypal-integration/smoke-token.mjs" <<'EOF'
import './load-env.mjs';
import { getPayPalAccessToken } from './paypal-client.mjs';

const token = await getPayPalAccessToken();
console.log(JSON.stringify({
  ok: Boolean(token.access_token),
  token_type: token.token_type,
  expires_in: token.expires_in,
}, null, 2));
EOF

cat > "$PROJECT_ROOT/paypal-integration/create-order.example.mjs" <<'EOF'
import './load-env.mjs';
import { createOrder } from './paypal-client.mjs';

const order = await createOrder();
console.log(JSON.stringify({
  id: order.id,
  status: order.status,
  links: order.links?.map((link) => ({ rel: link.rel, href: link.href })),
}, null, 2));
EOF

cat > "$PROJECT_ROOT/paypal-integration/test.mjs" <<'EOF'
import './load-env.mjs';
import { existsSync } from 'node:fs';
import { createOrder, getPayPalAccessToken } from './paypal-client.mjs';

let pass = 0;
let fail = 0;

function check(label, ok, detail = '') {
  if (ok) {
    console.log(`  OK  ${label}`);
    pass += 1;
  } else {
    console.log(`  FAIL  ${label}${detail ? ` - ${detail}` : ''}`);
    fail += 1;
  }
}

console.log('');
console.log('Running PayPal integration npm tests...');
console.log('');

check('PAYPAL_ENVIRONMENT is sandbox', process.env.PAYPAL_ENVIRONMENT === 'sandbox', 'PAYPAL_ENVIRONMENT must be sandbox');
check('PAYPAL_CLIENT_ID is set', Boolean(process.env.PAYPAL_CLIENT_ID), 'missing PAYPAL_CLIENT_ID');
check('PAYPAL_CLIENT_SECRET is set', Boolean(process.env.PAYPAL_CLIENT_SECRET), 'missing PAYPAL_CLIENT_SECRET');

try {
  const token = await getPayPalAccessToken();
  check('PayPal sandbox OAuth token exchange', Boolean(token.access_token && token.token_type));
} catch (error) {
  check('PayPal sandbox OAuth token exchange', false, error.message.replace(/\s+/g, ' '));
}

try {
  const order = await createOrder();
  check('PayPal sandbox order creation', Boolean(order.id && order.status), `order id/status missing`);
  if (order.id || order.status) {
    console.log(`  INFO  Sandbox order: ${order.id ?? '(missing id)'} ${order.status ?? '(missing status)'}`);
  }
} catch (error) {
  check('PayPal sandbox order creation', false, error.message.replace(/\s+/g, ' '));
}

check('Generated Node helper exists', existsSync(new URL('./paypal-client.mjs', import.meta.url)));

console.log('');
console.log(`Results: ${pass} passed, ${fail} failed`);
console.log('');

if (fail > 0) process.exit(1);
EOF

cat > "$PROJECT_ROOT/paypal-integration/README.md" <<'EOF'
# PayPal Node sandbox helper

Generated by TaskLab `paypal/setup-and-integrate`.

Required environment variables in your project `.env`:

```bash
PAYPAL_ENVIRONMENT=sandbox
PAYPAL_CLIENT_ID=<sandbox-client-id>
PAYPAL_CLIENT_SECRET=<sandbox-client-secret>
PAYPAL_CURRENCY=USD
PAYPAL_TEST_AMOUNT=1.00
```

Run the generated npm tests:

```bash
npm test --prefix paypal-integration
```

Smoke-test OAuth only:

```bash
npm run test:oauth --prefix paypal-integration
```

Create a sandbox order:

```bash
npm run create-order --prefix paypal-integration
```
EOF

echo "Generated PayPal Node helper:"
echo "  $PROJECT_ROOT/paypal-integration/package.json"
echo "  $PROJECT_ROOT/paypal-integration/load-env.mjs"
echo "  $PROJECT_ROOT/paypal-integration/paypal-client.mjs"
echo "  $PROJECT_ROOT/paypal-integration/test.mjs"
echo "  $PROJECT_ROOT/paypal-integration/smoke-token.mjs"
echo "  $PROJECT_ROOT/paypal-integration/create-order.example.mjs"

TASK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
tasklab_git_checkpoint "$TASK_DIR" "tasklab(paypal/setup-and-integrate): scaffold node integration"
