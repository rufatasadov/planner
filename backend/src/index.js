import 'dotenv/config';
import './sentry.js';
import { createApp } from './app.js';
import { migrate } from './migrate.js';

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET is not set (see .env.example)');
  process.exit(1);
}

const port = Number(process.env.PORT) || 3000;
await migrate();
createApp().listen(port, () => console.log(`API: http://localhost:${port}/api/v1`));
