import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import { requireAdmin, requireAuth } from './middleware/auth.js';
import adminRoutes from './routes/admin.js';
import authRoutes from './routes/auth.js';
import settingsRoutes from './routes/settings.js';
import projectRoutes from './routes/projects.js';
import taskRoutes from './routes/tasks.js';
import planRoutes from './routes/plans.js';
import noteRoutes from './routes/notes.js';
import billingRoutes, { webhookRouter } from './routes/billing.js';
import { HttpError } from './utils/http.js';
import { pickLanguage, translate } from './i18n.js';
import { reportError } from './sentry.js';

const envInt = (name, fallback) => Number(process.env[name]) || fallback;

// CORS_ORIGIN: '*' or a comma-separated list (web app, staging, capacitor://localhost for the mobile apps).
function corsOrigin() {
  const raw = (process.env.CORS_ORIGIN || '*').trim();
  if (raw === '*') return '*';
  return raw.split(',').map((s) => s.trim()).filter(Boolean);
}

const tooManyRequests = (_req, _res, next) => next(new HttpError(429, 'common.tooManyRequests'));

export function createApp() {
  const app = express();
  // Requests arrive through Caddy → nginx on private Docker networks; trust them so req.ip is the client.
  app.set('trust proxy', process.env.TRUST_PROXY || 'loopback, uniquelocal');
  app.disable('x-powered-by');

  app.use(helmet());
  app.use(cors({ origin: corsOrigin(), exposedHeaders: ['X-History-Start'] }));
  // Payment provider webhooks: raw body (for the signature), no auth and no rate limit.
  app.use('/api/v1/billing/webhooks', express.raw({ type: '*/*', limit: '1mb' }), webhookRouter);
  app.use(express.json({ limit: '1mb' }));
  // Express 5 leaves req.body undefined when a request has no body.
  app.use((req, _res, next) => {
    req.body ??= {};
    next();
  });

  const apiLimiter = rateLimit({
    windowMs: 60_000,
    limit: envInt('RATE_LIMIT_PER_MIN', 600),
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: tooManyRequests,
  });
  // Login/register only: slows down password guessing and mass sign-ups.
  const authLimiter = rateLimit({
    windowMs: 15 * 60_000,
    limit: envInt('AUTH_RATE_LIMIT', 30),
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: tooManyRequests,
  });

  const api = express.Router();
  api.get('/health', (_req, res) => res.json({ ok: true }));
  api.use(apiLimiter);
  api.use(['/auth/login', '/auth/register'], authLimiter);
  api.use('/auth', authRoutes);
  api.use('/settings', requireAuth, settingsRoutes);
  api.use('/projects', requireAuth, projectRoutes);
  api.use('/tasks', requireAuth, taskRoutes);
  api.use('/plans', requireAuth, planRoutes);
  api.use('/notes', requireAuth, noteRoutes);
  api.use('/billing', requireAuth, billingRoutes);
  api.use('/admin', requireAuth, requireAdmin, adminRoutes);
  app.use('/api/v1', api);

  app.use((_req, _res, next) => next(new HttpError(404, 'common.endpointNotFound')));

  // Errors are returned as { error: <translated message>, code: <message key>, details? }.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, _next) => {
    const lang = pickLanguage(req.headers['accept-language']);
    if (err.type === 'entity.parse.failed') err = new HttpError(400, 'validation.json');
    if (err.type === 'entity.too.large') err = new HttpError(413, 'validation.tooLarge');
    if (!(err instanceof HttpError)) {
      console.error(err);
      reportError(err, req);
      err = new HttpError(500, 'common.serverError');
    }
    res.status(err.status).json({ error: translate(lang, err.key, err.params), code: err.key, details: err.details });
  });

  return app;
}
