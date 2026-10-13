-- Paddle customer (ctm_...) linked on the first checkout; reused for later checkouts and the customer portal.
ALTER TABLE users ADD COLUMN IF NOT EXISTS paddle_customer_id VARCHAR(64) UNIQUE;

-- Provider-side update time of the last applied event: webhooks can arrive out of order,
-- and an older event must not overwrite a newer subscription state.
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS provider_updated_at TIMESTAMPTZ;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS customer_id VARCHAR(255);
