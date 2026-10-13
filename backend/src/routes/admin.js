import { Router } from 'express';
import { query } from '../db.js';
import { notFound, requireInt, requireOneOf } from '../utils/http.js';
import { isAdminEmail } from '../middleware/auth.js';
import { LIVE_SUBSCRIPTION_SQL, PRODUCTS } from '../services/billing.js';

const router = Router();

const PERIODS = ['7', '30', '90', '365'];

// Every user action that counts as activity, with its timestamp.
const EVENTS_SQL = `
  SELECT user_id, created_at AS ts FROM tasks
  UNION ALL SELECT user_id, updated_at FROM tasks WHERE updated_at > created_at
  UNION ALL SELECT user_id, created_at FROM projects
  UNION ALL SELECT user_id, created_at FROM plans
  UNION ALL SELECT user_id, started_at FROM work_sessions
  UNION ALL SELECT user_id, created_at FROM task_notes`;

const SESSION_SEC = `EXTRACT(EPOCH FROM COALESCE(ws.ended_at, now()) - ws.started_at)`;

/**
 * GET /admin/stats?days=7|30|90|365
 * Activity % = days with at least one action in the period / period length
 * (for users who registered during the period, only the days since registration count).
 * Plan execution % = tracked time / planned time of plans that already ended in the period.
 */
router.get('/stats', async (req, res) => {
  const days = Number(requireOneOf(String(req.query.days ?? '30'), 'days', PERIODS));
  const { rows: [{ tz }] } = await query(
    `SELECT COALESCE((SELECT timezone FROM user_settings WHERE user_id = $1), 'UTC') AS tz`,
    [req.userId],
  );

  const { rows: users } = await query(
    `WITH p AS (SELECT now() - make_interval(days => $1) AS since),
     ev AS (${EVENTS_SQL}),
     act AS (
       SELECT ev.user_id,
              count(DISTINCT (ev.ts AT TIME ZONE COALESCE(s.timezone, 'UTC'))::date) FILTER (WHERE ev.ts >= p.since) AS active_days,
              count(*) FILTER (WHERE ev.ts >= p.since) AS actions,
              max(ev.ts) AS last_activity
       FROM ev CROSS JOIN p LEFT JOIN user_settings s ON s.user_id = ev.user_id
       GROUP BY ev.user_id
     ),
     tk AS (
       SELECT user_id,
              count(*) AS total,
              count(*) FILTER (WHERE parent_id IS NOT NULL) AS subtasks,
              count(*) FILTER (WHERE status = 'todo') AS todo,
              count(*) FILTER (WHERE status = 'in_progress') AS in_progress,
              count(*) FILTER (WHERE status = 'done') AS done,
              count(*) FILTER (WHERE status = 'cancelled') AS cancelled,
              count(*) FILTER (WHERE created_at >= p.since) AS created_period,
              count(*) FILTER (WHERE status = 'done' AND updated_at >= p.since) AS done_period
       FROM tasks CROSS JOIN p GROUP BY user_id
     ),
     pl AS (
       SELECT pl.user_id,
              count(*) AS total,
              count(*) FILTER (WHERE pl.created_at >= p.since) AS created_period,
              COALESCE(sum(pl.end_min - pl.start_min) FILTER (
                WHERE pl.plan_date >= (p.since AT TIME ZONE s.timezone)::date
                  AND ((pl.plan_date::timestamp + pl.end_min * interval '1 minute') AT TIME ZONE s.timezone) <= now()
              ), 0) AS planned_min_ended
       FROM plans pl JOIN user_settings s ON s.user_id = pl.user_id CROSS JOIN p
       GROUP BY pl.user_id
     ),
     ws AS (
       SELECT ws.user_id,
              COALESCE(sum(${SESSION_SEC}), 0) AS tracked_sec,
              COALESCE(sum(${SESSION_SEC}) FILTER (WHERE ws.started_at >= p.since), 0) AS tracked_sec_period,
              COALESCE(sum(${SESSION_SEC}) FILTER (
                WHERE pl.plan_date >= (p.since AT TIME ZONE s.timezone)::date
                  AND ((pl.plan_date::timestamp + pl.end_min * interval '1 minute') AT TIME ZONE s.timezone) <= now()
              ), 0) AS tracked_sec_ended,
              bool_or(ws.ended_at IS NULL) AS tracking_now
       FROM work_sessions ws
       JOIN plans pl ON pl.id = ws.plan_id
       JOIN user_settings s ON s.user_id = ws.user_id
       CROSS JOIN p
       GROUP BY ws.user_id
     ),
     nt AS (
       SELECT user_id, count(*) AS total, count(*) FILTER (WHERE created_at >= p.since) AS created_period
       FROM task_notes CROSS JOIN p GROUP BY user_id
     ),
     pr AS (SELECT user_id, count(*) AS total FROM projects GROUP BY user_id),
     sub AS (
       SELECT DISTINCT ON (s.user_id) s.user_id, s.product_id, s.provider
       FROM subscriptions s WHERE ${LIVE_SUBSCRIPTION_SQL}
       ORDER BY s.user_id, (s.provider = 'promo'), s.current_period_end DESC NULLS FIRST
     )
     SELECT u.id, u.name, u.email, u.created_at, u.last_seen_at, u.trial_ends_at,
            sub.product_id AS subscription_product, sub.provider AS subscription_provider,
            COALESCE(pr.total, 0)::int AS projects,
            COALESCE(tk.total, 0)::int AS tasks,
            COALESCE(tk.subtasks, 0)::int AS subtasks,
            COALESCE(tk.todo, 0)::int AS tasks_todo,
            COALESCE(tk.in_progress, 0)::int AS tasks_in_progress,
            COALESCE(tk.done, 0)::int AS tasks_done,
            COALESCE(tk.cancelled, 0)::int AS tasks_cancelled,
            COALESCE(tk.created_period, 0)::int AS tasks_created_period,
            COALESCE(tk.done_period, 0)::int AS tasks_done_period,
            COALESCE(pl.total, 0)::int AS plans,
            COALESCE(pl.created_period, 0)::int AS plans_period,
            COALESCE(pl.planned_min_ended, 0)::int AS planned_min_ended,
            round(COALESCE(ws.tracked_sec, 0))::int AS tracked_sec,
            round(COALESCE(ws.tracked_sec_period, 0))::int AS tracked_sec_period,
            round(COALESCE(ws.tracked_sec_ended, 0))::int AS tracked_sec_ended,
            COALESCE(ws.tracking_now, false) AS tracking_now,
            COALESCE(nt.total, 0)::int AS notes,
            COALESCE(nt.created_period, 0)::int AS notes_period,
            COALESCE(act.active_days, 0)::int AS active_days,
            COALESCE(act.actions, 0)::int AS actions_period,
            act.last_activity,
            -- days of the period the account existed (at least 1)
            GREATEST(1, LEAST($1, (now()::date - u.created_at::date) + 1))::int AS period_days
     FROM users u
     LEFT JOIN pr ON pr.user_id = u.id
     LEFT JOIN tk ON tk.user_id = u.id
     LEFT JOIN pl ON pl.user_id = u.id
     LEFT JOIN ws ON ws.user_id = u.id
     LEFT JOIN nt ON nt.user_id = u.id
     LEFT JOIN act ON act.user_id = u.id
     LEFT JOIN sub ON sub.user_id = u.id
     ORDER BY u.created_at`,
    [days],
  );

  for (const u of users) {
    u.activity_pct = Math.min(100, Math.round((u.active_days / u.period_days) * 100));
    u.completion_pct = u.tasks - u.tasks_cancelled > 0 ? Math.round((u.tasks_done / (u.tasks - u.tasks_cancelled)) * 100) : null;
    u.execution_pct = u.planned_min_ended > 0 ? Math.round((u.tracked_sec_ended / (u.planned_min_ended * 60)) * 100) : null;
    u.plan_source = isAdminEmail(u.email)
      ? 'admin'
      : u.subscription_provider
        ? (u.subscription_provider === 'promo' ? 'promo' : 'subscription')
        : u.trial_ends_at && new Date(u.trial_ends_at) > new Date()
          ? 'trial'
          : null;
  }
  const subscribers = users.filter((u) => u.plan_source === 'subscription');
  const mrr = subscribers.reduce((s, u) => {
    const p = PRODUCTS[u.subscription_product];
    return p ? s + p.usd / p.months : s;
  }, 0);

  // Daily series in the admin's time zone.
  const { rows: daily } = await query(
    `WITH d AS (
       SELECT generate_series((now() AT TIME ZONE $2)::date - ($1 - 1), (now() AT TIME ZONE $2)::date, interval '1 day')::date AS day
     ),
     ev AS (${EVENTS_SQL})
     SELECT to_char(d.day, 'YYYY-MM-DD') AS date,
       (SELECT count(*) FROM users u WHERE (u.created_at AT TIME ZONE $2)::date = d.day)::int AS new_users,
       (SELECT count(DISTINCT ev.user_id) FROM ev WHERE (ev.ts AT TIME ZONE $2)::date = d.day)::int AS active_users,
       (SELECT count(*) FROM tasks t WHERE (t.created_at AT TIME ZONE $2)::date = d.day)::int AS tasks_created,
       (SELECT count(*) FROM tasks t WHERE t.status = 'done' AND (t.updated_at AT TIME ZONE $2)::date = d.day)::int AS tasks_done,
       (SELECT count(*) FROM plans pl WHERE pl.plan_date = d.day)::int AS plans,
       (SELECT round(COALESCE(sum(${SESSION_SEC}), 0))::int FROM work_sessions ws
          WHERE (ws.started_at AT TIME ZONE $2)::date = d.day) AS tracked_sec
     FROM d ORDER BY d.day`,
    [days, tz],
  );

  const sum = (key) => users.reduce((s, u) => s + u[key], 0);
  const weekAgo = Date.now() - 7 * 864e5;
  const dayAgo = Date.now() - 864e5;
  const since = Date.now() - days * 864e5;
  const planned = sum('planned_min_ended') * 60;
  const nonCancelled = sum('tasks') - sum('tasks_cancelled');

  res.json({
    days,
    timezone: tz,
    generated_at: new Date().toISOString(),
    overview: {
      users: users.length,
      new_users: users.filter((u) => new Date(u.created_at) >= since).length,
      active_users_period: users.filter((u) => u.active_days > 0).length,
      active_users_7d: users.filter((u) => u.last_activity && new Date(u.last_activity) >= weekAgo).length,
      active_users_24h: users.filter((u) => u.last_activity && new Date(u.last_activity) >= dayAgo).length,
      online_now: users.filter((u) => u.tracking_now).length,
      projects: sum('projects'),
      tasks: sum('tasks'),
      subtasks: sum('subtasks'),
      tasks_by_status: {
        todo: sum('tasks_todo'),
        in_progress: sum('tasks_in_progress'),
        done: sum('tasks_done'),
        cancelled: sum('tasks_cancelled'),
      },
      tasks_created_period: sum('tasks_created_period'),
      tasks_done_period: sum('tasks_done_period'),
      completion_pct: nonCancelled > 0 ? Math.round((sum('tasks_done') / nonCancelled) * 100) : null,
      plans: sum('plans'),
      plans_period: sum('plans_period'),
      tracked_sec: sum('tracked_sec'),
      tracked_sec_period: sum('tracked_sec_period'),
      execution_pct: planned > 0 ? Math.round((sum('tracked_sec_ended') / planned) * 100) : null,
      notes: sum('notes'),
      notes_period: sum('notes_period'),
      avg_activity_pct: users.length ? Math.round(users.reduce((s, u) => s + u.activity_pct, 0) / users.length) : 0,
      billing: {
        subscribers: subscribers.length,
        trialing: users.filter((u) => u.plan_source === 'trial').length,
        promo: users.filter((u) => u.plan_source === 'promo').length,
        free: users.filter((u) => !u.plan_source).length,
        mrr_usd: Math.round(mrr * 100) / 100,
      },
    },
    daily,
    users,
  });
});

// POST /admin/users/:id/pro { days: 30 | 365 | null }  — free Pro (provider 'promo'); days = null means no end.
router.post('/users/:id/pro', async (req, res) => {
  const userId = requireInt(req.params.id, 'id', { min: 1 });
  const days = req.body.days == null ? null : requireInt(req.body.days, 'days', { min: 1, max: 3650 });
  const { rowCount } = await query('SELECT 1 FROM users WHERE id = $1', [userId]);
  if (!rowCount) throw notFound('auth.userNotFound');
  await query(`UPDATE subscriptions SET status = 'canceled', updated_at = now() WHERE user_id = $1 AND provider = 'promo'`, [userId]);
  await query(
    `INSERT INTO subscriptions (user_id, provider, external_id, product_id, status, current_period_end, will_renew)
     VALUES ($1, 'promo', $2, 'pro_promo', 'active', CASE WHEN $3::int IS NULL THEN NULL ELSE now() + make_interval(days => $3::int) END, false)`,
    [userId, `promo-${userId}-${Date.now()}`, days],
  );
  res.status(201).json({ ok: true });
});

router.delete('/users/:id/pro', async (req, res) => {
  const userId = requireInt(req.params.id, 'id', { min: 1 });
  await query(`UPDATE subscriptions SET status = 'canceled', updated_at = now() WHERE user_id = $1 AND provider = 'promo'`, [userId]);
  res.json({ ok: true });
});

export default router;
