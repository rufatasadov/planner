import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { migrate } from './migrate.js';
import { requireAuth } from './middleware/auth.js';
import authRoutes from './routes/auth.js';
import settingsRoutes from './routes/settings.js';
import projectRoutes from './routes/projects.js';
import taskRoutes from './routes/tasks.js';
import planRoutes from './routes/plans.js';
import { HttpError } from './utils/http.js';
import { pickLanguage, translate } from './i18n.js';

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET is not set (see .env.example)');
  process.exit(1);
}

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
// Express 5 leaves req.body undefined when a request has no body.
app.use((req, _res, next) => {
  req.body ??= {};
  next();
});

const api = express.Router();
api.get('/health', (_req, res) => res.json({ ok: true }));
api.use('/auth', authRoutes);
api.use('/settings', requireAuth, settingsRoutes);
api.use('/projects', requireAuth, projectRoutes);
api.use('/tasks', requireAuth, taskRoutes);
api.use('/plans', requireAuth, planRoutes);
app.use('/api/v1', api);

app.use((_req, _res, next) => next(new HttpError(404, 'common.endpointNotFound')));

// Errors are returned as { error: <translated message>, code: <message key>, details? }.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  const lang = pickLanguage(req.headers['accept-language']);
  if (err.type === 'entity.parse.failed') err = new HttpError(400, 'validation.json');
  if (!(err instanceof HttpError)) {
    console.error(err);
    err = new HttpError(500, 'common.serverError');
  }
  res.status(err.status).json({ error: translate(lang, err.key, err.params), code: err.key, details: err.details });
});

const port = Number(process.env.PORT) || 3000;
await migrate();
app.listen(port, () => console.log(`API: http://localhost:${port}/api/v1`));
