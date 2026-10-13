// Legal pages (English only — the binding version reviewed by the payment provider).
// Static, trusted HTML rendered with v-html.
import { AUTHOR } from './about';

export const LEGAL_UPDATED = '2026-10-14';

const OPERATOR = `OneLinePlanner (“the Service”, available at onelineplanner.com) is operated by ${AUTHOR.name}, an individual based in the Republic of Azerbaijan (“we”, “us”).`;
const CONTACT = `<a href="mailto:${AUTHOR.email}">${AUTHOR.email}</a>`;

const terms = `
<p>${OPERATOR} By creating an account or using the Service you agree to these Terms of Service. If you do not agree, do not use the Service.</p>

<h2>1. The Service</h2>
<p>OneLinePlanner is a web application for planning the working day on a timeline, managing projects and tasks, tracking working time and keeping work notes. We may change, add or remove features over time.</p>

<h2>2. Accounts</h2>
<ul>
  <li>You must provide a valid email address and keep your password confidential. You are responsible for all activity under your account.</li>
  <li>You must be at least 16 years old to use the Service.</li>
  <li>One person may not share an account with others or create accounts to avoid plan limits.</li>
</ul>

<h2>3. Plans, trial and subscriptions</h2>
<ul>
  <li><strong>Free plan.</strong> The Free plan is available without payment and has limits (currently 3 projects and the last 14 days of plan history).</li>
  <li><strong>Free trial.</strong> New accounts receive a 14-day trial of the Pro plan. No payment details are required for the trial and nothing is charged when it ends; the account moves to the Free plan automatically.</li>
  <li><strong>Pro subscription.</strong> Pro is offered as a monthly or yearly subscription at the prices shown on the <a href="/pricing">Pricing</a> page. Subscriptions renew automatically at the end of each billing period until cancelled.</li>
  <li><strong>Cancellation.</strong> You can cancel at any time in Settings → Subscription → Manage, or from the link in your payment receipt. After cancellation Pro remains active until the end of the paid period and is not renewed.</li>
  <li><strong>Price changes.</strong> We may change prices for future billing periods. We will notify you by email at least 14 days before a price change affects your subscription.</li>
  <li><strong>Limits never delete data.</strong> If your account moves from Pro to Free, your data is kept; plan limits only restrict creating new projects and viewing older history.</li>
</ul>

<h2>4. Payments through Paddle</h2>
<p>Our order process is conducted by our online reseller Paddle.com. Paddle.com is the Merchant of Record for all our orders. Paddle provides all customer service inquiries and handles returns. Payments, taxes, invoices and refunds are processed by Paddle under the <a href="https://www.paddle.com/legal/checkout-buyer-terms" target="_blank" rel="noopener">Paddle Buyer Terms</a>. We do not receive or store your card details.</p>

<h2>5. Refunds</h2>
<p>Refunds are described in our <a href="/refund">Refund Policy</a>.</p>

<h2>6. Your content</h2>
<p>You keep all rights to the projects, tasks, plans and notes you create (“Your Content”). You give us a limited permission to store, process and display Your Content only to provide the Service to you. We do not sell Your Content and do not use it for advertising.</p>

<h2>7. Acceptable use</h2>
<p>You agree not to: break the law using the Service; attempt to access other users’ data; interfere with or overload the Service (including automated mass requests); reverse engineer or resell the Service; or upload malicious code.</p>

<h2>8. Availability</h2>
<p>We work to keep the Service available and to back up data daily, but the Service is provided “as is” and “as available”, without warranties of any kind, to the extent permitted by law. Planned maintenance and unexpected outages may happen.</p>

<h2>9. Limitation of liability</h2>
<p>To the maximum extent permitted by law, we are not liable for indirect, incidental or consequential damages, or loss of profits or data. Our total liability for any claim related to the Service is limited to the amount you paid for the Service in the 12 months before the claim. Nothing in these Terms limits rights that consumers have under mandatory law.</p>

<h2>10. Termination</h2>
<p>You may stop using the Service and ask us to delete your account at any time. We may suspend or terminate accounts that seriously or repeatedly violate these Terms; if we terminate a paid account without cause, we will refund the unused part of the current period.</p>

<h2>11. Changes to these Terms</h2>
<p>We may update these Terms. Material changes will be announced by email or in the app at least 14 days before they take effect. Continuing to use the Service after that means you accept the new Terms.</p>

<h2>12. Governing law</h2>
<p>These Terms are governed by the laws of the Republic of Azerbaijan, without prejudice to the mandatory consumer protection rules of your country of residence.</p>

<h2>13. Contact</h2>
<p>Questions about these Terms: ${CONTACT}.</p>
`;

const privacy = `
<p>${OPERATOR} This Privacy Policy explains what personal data we collect, why, and what rights you have. We are the data controller for the data described here.</p>

<h2>1. Data we collect</h2>
<ul>
  <li><strong>Account data:</strong> your name, email address and a hashed password (we never store the password itself).</li>
  <li><strong>Content:</strong> projects, tasks, plans, time-tracking records, notes and settings (such as working hours, time zone, language and theme).</li>
  <li><strong>Subscription data:</strong> your plan, trial end date and subscription status. Card and billing details are collected by Paddle, not by us; we receive only a customer and subscription identifier and the subscription status.</li>
  <li><strong>Technical data:</strong> IP address and browser information in server logs, the time you were last active, and error reports when something breaks.</li>
</ul>

<h2>2. How we use it</h2>
<ul>
  <li>to provide the Service and keep your data in sync (performance of a contract);</li>
  <li>to send service emails — email confirmation, password reset, receipts and important account notices (performance of a contract);</li>
  <li>to keep the Service secure, prevent abuse and fix errors (legitimate interest);</li>
  <li>to meet legal and tax obligations (legal obligation).</li>
</ul>
<p>We do not sell personal data, do not show ads and do not use third-party advertising or tracking cookies.</p>

<h2>3. Service providers</h2>
<p>We share data only with providers that help us run the Service, under agreements that protect it:</p>
<ul>
  <li><strong>Paddle.com</strong> — payments, taxes and invoices (Merchant of Record);</li>
  <li><strong>Resend</strong> — delivery of service emails;</li>
  <li><strong>Sentry</strong> — error reports (stored in the EU);</li>
  <li>our <strong>hosting provider</strong> — servers and encrypted backups.</li>
</ul>
<p>Some providers may process data outside your country. Where required, transfers are protected by standard contractual clauses or equivalent safeguards.</p>

<h2>4. Cookies and local storage</h2>
<p>We do not use advertising cookies. The app stores your login token and display preferences (language, theme) in your browser’s local storage so you stay signed in. Paddle may set cookies needed for checkout and fraud prevention when you open the payment window.</p>

<h2>5. Retention</h2>
<p>We keep your data while your account exists. When you delete your account (or ask us to), we delete your data within 30 days; copies in backups are removed within a further 14 days. We keep billing records as long as tax law requires.</p>

<h2>6. Your rights</h2>
<p>Depending on where you live (for example under the GDPR), you have the right to access, correct, export or delete your personal data, to object to or restrict processing, and to complain to your data protection authority. To use these rights, email ${CONTACT}. We answer within 30 days.</p>

<h2>7. Security</h2>
<p>Connections are encrypted with HTTPS, passwords are hashed, access to servers is restricted and backups are made daily. No system is perfectly secure, but we take reasonable measures to protect your data and will notify you of a breach where the law requires it.</p>

<h2>8. Children</h2>
<p>The Service is not intended for children under 16, and we do not knowingly collect their data.</p>

<h2>9. Changes</h2>
<p>We may update this policy. Material changes will be announced by email or in the app before they take effect.</p>

<h2>10. Contact</h2>
<p>Privacy questions and requests: ${CONTACT}.</p>
`;

const refund = `
<p>We want you to be happy with OneLinePlanner Pro. This Refund Policy applies to all payments for the Service. Payments are processed by our reseller and Merchant of Record, Paddle.com.</p>

<h2>1. Try before you pay</h2>
<p>Every new account gets a 14-day Pro trial without entering payment details, so you can decide whether Pro is right for you before paying anything.</p>

<h2>2. 14-day money-back guarantee</h2>
<p>If you are not satisfied, you can request a <strong>full refund within 14 days</strong> of any payment — the first payment of a subscription or a renewal, monthly or yearly. No questions asked.</p>

<h2>3. How to request a refund</h2>
<ul>
  <li>Use the link in the receipt email from Paddle, or visit <a href="https://paddle.net" target="_blank" rel="noopener">paddle.net</a> to find your order; or</li>
  <li>email us at ${CONTACT} with the email address of your account.</li>
</ul>
<p>Refunds are returned to the original payment method, usually within 5–10 business days depending on your bank.</p>

<h2>4. After a refund</h2>
<p>When a payment is refunded, the Pro subscription for that period ends and your account moves to the Free plan. Your data is not deleted.</p>

<h2>5. Cancelling without a refund</h2>
<p>You can cancel at any time in Settings → Subscription → Manage. Cancelling stops future renewals; Pro stays active until the end of the period already paid for.</p>

<h2>6. Your statutory rights</h2>
<p>This policy does not limit any rights you have under the consumer protection laws of your country.</p>
`;

export const LEGAL = {
  terms: { titleKey: 'site.footer.terms', html: terms },
  privacy: { titleKey: 'site.footer.privacy', html: privacy },
  refund: { titleKey: 'site.footer.refund', html: refund },
};
