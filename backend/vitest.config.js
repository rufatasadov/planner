import { defineConfig } from 'vitest/config';

// Tests run against a throwaway database (recreated on every run) on the same Postgres server.
const TEST_DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgres://planner:planner@localhost:5433/planner_test';

export default defineConfig({
  test: {
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: TEST_DATABASE_URL,
      JWT_SECRET: 'test-secret',
      ADMIN_EMAILS: 'admin@test.local',
      // backend/.env (loaded by dotenv) may hold a real DSN; dotenv never overrides variables that are already set.
      SENTRY_DSN: '',
      // Never call the real Paddle API from tests; webhooks are signed with this secret.
      PADDLE_ENV: 'sandbox',
      PADDLE_API_KEY: '',
      PADDLE_CLIENT_TOKEN: '',
      PADDLE_PRICE_PRO_MONTHLY: 'pri_test_monthly',
      PADDLE_PRICE_PRO_YEARLY: 'pri_test_yearly',
      PADDLE_WEBHOOK_SECRET: 'pdl_ntfset_test_secret',
    },
    globalSetup: './test/global-setup.js',
    fileParallelism: false,
  },
});
