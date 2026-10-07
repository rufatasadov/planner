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

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET is not set (see .env.example)');
  process.exit(1);
}

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

const api = express.Router();
api.get('/health', (_req, res) => res.json({ ok: true }));
api.use('/auth', authRoutes);
api.use('/settings', requireAuth, settingsRoutes);
api.use('/projects', requireAuth, projectRoutes);
api.use('/tasks', requireAuth, taskRoutes);
api.use('/plans', requireAuth, planRoutes);
app.use('/api/v1', api);

app.use((_req, res) => res.status(404).json({ error: 'Endpoint tapılmadı' }));

// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  if (err.status) return res.status(err.status).json({ error: err.message, details: err.details });
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON düzgün deyil' });
  console.error(err);
  res.status(500).json({ error: 'Server xətası' });
});

const port = Number(process.env.PORT) || 3000;
await migrate();
app.listen(port, () => console.log(`API: http://localhost:${port}/api/v1`));
