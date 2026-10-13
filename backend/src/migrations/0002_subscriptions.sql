-- Free / Pro plans. A user is Pro while on trial (users.trial_ends_at) or with a live subscription.
ALTER TABLE users ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ;
-- Existing accounts get the same 14-day Pro trial as new sign-ups, starting now.
UPDATE users SET trial_ends_at = now() + interval '14 days' WHERE trial_ends_at IS NULL;

CREATE TABLE IF NOT EXISTS subscriptions (
  id                 SERIAL PRIMARY KEY,
  user_id            INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider           VARCHAR(32) NOT NULL,   -- paddle | app_store | play_store | promo
  external_id        VARCHAR(255) NOT NULL,  -- provider's subscription id
  product_id         VARCHAR(64) NOT NULL,   -- pro_monthly | pro_yearly | ...
  status             VARCHAR(32) NOT NULL,   -- trialing | active | past_due | paused | canceled
  current_period_end TIMESTAMPTZ,            -- NULL = no end (e.g. lifetime promo)
  will_renew         BOOLEAN NOT NULL DEFAULT true,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, external_id)
);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);

-- Raw webhook log: the primary key makes redelivered events a no-op.
CREATE TABLE IF NOT EXISTS billing_events (
  id          VARCHAR(255) PRIMARY KEY,
  provider    VARCHAR(32) NOT NULL,
  type        VARCHAR(64) NOT NULL,
  payload     JSONB NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
