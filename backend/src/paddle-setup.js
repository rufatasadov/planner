// Creates (or finds) the Pro product, its prices and the webhook destination in Paddle,
// then prints the env lines to add. Safe to run repeatedly.
//
//   node src/paddle-setup.js                                   # product + prices
//   node src/paddle-setup.js --webhook-url https://host/api/v1/billing/webhooks/paddle
import 'dotenv/config';
import { paddleApi, paddleConfig } from './services/paddle.js';

const PRODUCT_KEY = 'planner_pro';
const PRICES = [
  { key: 'pro_monthly', env: 'PADDLE_PRICE_PRO_MONTHLY', name: 'Monthly', amount: '499', interval: 'month' },
  { key: 'pro_yearly', env: 'PADDLE_PRICE_PRO_YEARLY', name: 'Yearly', amount: '3999', interval: 'year' },
];
export const WEBHOOK_EVENTS = [
  'subscription.created',
  'subscription.updated',
  'subscription.activated',
  'subscription.trialing',
  'subscription.past_due',
  'subscription.paused',
  'subscription.resumed',
  'subscription.canceled',
  'transaction.completed',
];

async function listAll(path) {
  return paddleApi(`${path}${path.includes('?') ? '&' : '?'}per_page=200`);
}

async function ensureProduct() {
  const existing = (await listAll('/products?status=active')).find((p) => p.custom_data?.key === PRODUCT_KEY);
  if (existing) return existing;
  return paddleApi('/products', {
    method: 'POST',
    body: {
      name: 'OneLinePlanner Pro',
      description: 'Unlimited projects and plan history.',
      tax_category: 'standard',
      custom_data: { key: PRODUCT_KEY },
    },
  });
}

async function ensurePrice(productId, p) {
  const existing = (await listAll(`/prices?product_id=${productId}&status=active`)).find((x) => x.custom_data?.key === p.key);
  if (existing) return existing;
  return paddleApi('/prices', {
    method: 'POST',
    body: {
      product_id: productId,
      description: `OneLinePlanner Pro — ${p.name}`,
      name: p.name,
      unit_price: { amount: p.amount, currency_code: 'USD' },
      billing_cycle: { interval: p.interval, frequency: 1 },
      tax_mode: 'account_setting',
      custom_data: { key: p.key },
    },
  });
}

async function ensureWebhook(url) {
  const existing = (await paddleApi('/notification-settings')).find((n) => n.destination === url);
  if (existing) {
    return paddleApi(`/notification-settings/${existing.id}`, {
      method: 'PATCH',
      body: { active: true, subscribed_events: WEBHOOK_EVENTS },
    });
  }
  return paddleApi('/notification-settings', {
    method: 'POST',
    body: {
      description: 'OneLinePlanner backend',
      type: 'url',
      destination: url,
      api_version: 1,
      traffic_source: 'all',
      subscribed_events: WEBHOOK_EVENTS,
    },
  });
}

async function main() {
  const { env, apiKey } = paddleConfig();
  if (!apiKey) throw new Error('PADDLE_API_KEY is not set');
  const i = process.argv.indexOf('--webhook-url');
  const webhookUrl = i > 0 ? process.argv[i + 1] : null;

  console.log(`Paddle ${env}`);
  const product = await ensureProduct();
  console.log(`product  ${product.id}  ${product.name}`);
  const lines = [];
  for (const p of PRICES) {
    const price = await ensurePrice(product.id, p);
    console.log(`price    ${price.id}  ${p.key}  ${price.unit_price.amount} ${price.unit_price.currency_code}/${p.interval}`);
    lines.push(`${p.env}=${price.id}`);
  }
  if (webhookUrl) {
    const n = await ensureWebhook(webhookUrl);
    console.log(`webhook  ${n.id}  ${n.destination}`);
    lines.push(`PADDLE_WEBHOOK_SECRET=${n.endpoint_secret_key}`);
  }
  console.log('\nAdd to .env:\n' + lines.join('\n'));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
