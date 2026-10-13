import crypto from 'node:crypto';

// Paddle Billing (paddle.com): checkout, subscriptions, customer portal.
// PADDLE_ENV=sandbox uses the sandbox API; anything else is live.

const API_BASE = {
  sandbox: 'https://sandbox-api.paddle.com',
  production: 'https://api.paddle.com',
};

export function paddleConfig() {
  const env = process.env.PADDLE_ENV === 'sandbox' ? 'sandbox' : 'production';
  return {
    env,
    apiBase: API_BASE[env],
    apiKey: process.env.PADDLE_API_KEY || '',
    clientToken: process.env.PADDLE_CLIENT_TOKEN || '',
    webhookSecret: process.env.PADDLE_WEBHOOK_SECRET || '',
    prices: {
      pro_monthly: process.env.PADDLE_PRICE_PRO_MONTHLY || '',
      pro_yearly: process.env.PADDLE_PRICE_PRO_YEARLY || '',
    },
  };
}

export const paddleEnabled = () => {
  const c = paddleConfig();
  return Boolean(c.apiKey && c.clientToken && c.prices.pro_monthly && c.prices.pro_yearly);
};

export class PaddleError extends Error {
  constructor(status, body) {
    super(`Paddle API ${status}: ${body?.error?.code || ''} ${body?.error?.detail || ''}`.trim());
    this.status = status;
    this.code = body?.error?.code;
    this.body = body;
  }
}

/** Calls the Paddle API and returns `data` from the response envelope. */
export async function paddleApi(path, { method = 'GET', body } = {}) {
  const { apiBase, apiKey } = paddleConfig();
  const res = await fetch(apiBase + path, {
    method,
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(15_000),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) throw new PaddleError(res.status, json);
  return json.data;
}

// Rejects replays of old notifications; Paddle retries with a fresh signature each time.
const SIGNATURE_MAX_AGE_SEC = 5 * 60;

/**
 * Verifies the Paddle-Signature header ("ts=...;h1=...") against the raw request body.
 * Several h1 values can be present while a secret is being rotated.
 */
export function verifyWebhookSignature(rawBody, header, secret, nowSec = Math.floor(Date.now() / 1000)) {
  if (!header || !secret || !rawBody) return false;
  let ts = null;
  const hashes = [];
  for (const part of String(header).split(';')) {
    const [k, v] = part.split('=');
    if (k === 'ts') ts = Number(v);
    else if (k === 'h1' && v) hashes.push(v);
  }
  if (!Number.isFinite(ts) || !hashes.length) return false;
  if (Math.abs(nowSec - ts) > SIGNATURE_MAX_AGE_SEC) return false;

  const expected = crypto.createHmac('sha256', secret).update(`${ts}:${rawBody}`).digest();
  return hashes.some((h) => {
    const got = Buffer.from(h, 'hex');
    return got.length === expected.length && crypto.timingSafeEqual(got, expected);
  });
}

/** Test helper / simulation: builds a valid Paddle-Signature header. */
export function signWebhook(rawBody, secret, ts = Math.floor(Date.now() / 1000)) {
  const h1 = crypto.createHmac('sha256', secret).update(`${ts}:${rawBody}`).digest('hex');
  return `ts=${ts};h1=${h1}`;
}
