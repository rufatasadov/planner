import api from '../api';
import { locale } from '../i18n';
import { theme } from '../theme';
import { useAuthStore } from '../stores/auth';

// Paddle.js is loaded only when the user starts a checkout.
const SCRIPT_URL = 'https://cdn.paddle.com/paddle/v2/paddle.js';
// Paddle checkout has no Azerbaijani; English is the fallback.
const PADDLE_LOCALES = { en: 'en', ru: 'ru' };

let ready = null;
const listeners = new Set();

/** Subscribes to Paddle.js checkout events (checkout.completed, checkout.closed, ...). Returns an unsubscribe function. */
export function onPaddleEvent(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function loadScript() {
  return new Promise((resolve, reject) => {
    const s = document.createElement('script');
    s.src = SCRIPT_URL;
    s.async = true;
    s.onload = () => resolve(window.Paddle);
    s.onerror = () => reject(new Error('Paddle.js failed to load'));
    document.head.appendChild(s);
  });
}

function initPaddle({ environment, client_token }) {
  ready ??= loadScript()
    .then((Paddle) => {
      if (environment === 'sandbox') Paddle.Environment.set('sandbox');
      Paddle.Initialize({ token: client_token, eventCallback: (e) => listeners.forEach((fn) => fn(e)) });
      return Paddle;
    })
    .catch((err) => {
      ready = null;
      throw err;
    });
  return ready;
}

/** Creates a checkout for the plan on the server and opens Paddle's overlay. */
export async function openCheckout(product) {
  const { data } = await api.post('/billing/checkout', { product });
  const Paddle = await initPaddle(data);
  Paddle.Checkout.open({
    transactionId: data.transaction_id,
    settings: {
      displayMode: 'overlay',
      theme: theme.value === 'light' ? 'light' : 'dark',
      locale: PADDLE_LOCALES[locale.value] ?? 'en',
      allowLogout: false,
    },
  });
}

/**
 * Pro is granted by the webhook, which can arrive a few seconds after the payment.
 * Resolves true once /auth/me reports a paid subscription, false on timeout.
 */
export async function waitForSubscription({ timeoutMs = 60_000, intervalMs = 2_000 } = {}) {
  const auth = useAuthStore();
  const until = Date.now() + timeoutMs;
  while (Date.now() < until) {
    await auth.fetchMe().catch(() => {});
    if (auth.user?.billing?.source === 'subscription') return true;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  return false;
}

/** Opens Paddle's customer portal (cancel, change card, invoices) in a new tab. */
export async function openPortal() {
  // Open the tab synchronously so the popup blocker allows it, then point it at the portal.
  const tab = window.open('', '_blank');
  try {
    const { data } = await api.post('/billing/portal');
    if (tab) tab.location.href = data.url;
    else window.location.href = data.url;
  } catch (err) {
    tab?.close();
    throw err;
  }
}
