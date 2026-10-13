// Transactional email through Resend (resend.com). Without RESEND_API_KEY emails are only logged,
// so local development and tests work without an account.

const RESEND_URL = 'https://api.resend.com/emails';

/** Emails "sent" while RESEND_API_KEY is not set (inspected by tests). */
export const outbox = [];

export const appUrl = () => (process.env.APP_URL || 'http://localhost:5173').replace(/\/+$/, '');

export async function sendMail({ to, subject, html, text }) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) {
    outbox.push({ to, subject, html, text });
    if (outbox.length > 100) outbox.shift();
    if (process.env.NODE_ENV !== 'test') console.log(`[mail] to=${to} subject="${subject}"\n${text}`);
    return;
  }
  const res = await fetch(RESEND_URL, {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from: process.env.MAIL_FROM || 'OneLinePlanner <no-reply@onelineplanner.com>',
      to: [to],
      subject,
      html,
      text,
    }),
    signal: AbortSignal.timeout(15_000),
  });
  if (!res.ok) throw new Error(`Resend ${res.status}: ${await res.text().catch(() => '')}`);
}
