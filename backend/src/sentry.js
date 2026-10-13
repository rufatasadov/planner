import * as Sentry from '@sentry/node';

// Error reporting is enabled only when SENTRY_DSN is set.
const enabled = Boolean(process.env.SENTRY_DSN);

if (enabled) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.SENTRY_ENVIRONMENT || process.env.NODE_ENV || 'development',
    sendDefaultPii: false,
  });
}

export function reportError(err, req) {
  if (!enabled) return;
  Sentry.withScope((scope) => {
    if (req) {
      scope.setTag('route', `${req.method} ${req.baseUrl}${req.route?.path ?? req.path}`);
      if (req.userId) scope.setUser({ id: String(req.userId) });
    }
    Sentry.captureException(err);
  });
}
