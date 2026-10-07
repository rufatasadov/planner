import { Router } from 'express';
import { query, withTransaction } from '../db.js';
import { badRequest, conflict, notFound, requireDate, requireInt } from '../utils/http.js';
import { getOwnedProject } from './projects.js';
import { getSettings } from './settings.js';

const router = Router();

const SHIFT_MODES = ['none', 'next', 'all'];

const fmt = (m) => `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`;

async function loadPlans(db, userId, whereSql, params) {
  const { rows: plans } = await db.query(
    `SELECT pl.*, p.name AS project_name, p.color AS project_color
     FROM plans pl JOIN projects p ON p.id = pl.project_id
     WHERE pl.user_id = $1 AND ${whereSql}
     ORDER BY pl.plan_date, pl.start_min`,
    [userId, ...params],
  );
  if (!plans.length) return [];
  const { rows: tasks } = await db.query(
    `SELECT pt.plan_id, t.id, t.title, t.status, t.description
     FROM plan_tasks pt JOIN tasks t ON t.id = pt.task_id
     WHERE pt.plan_id = ANY($1::int[])
     ORDER BY t.created_at`,
    [plans.map((p) => p.id)],
  );
  return plans.map((p) => ({
    ...p,
    tasks: tasks.filter((t) => t.plan_id === p.id).map(({ plan_id, ...t }) => t),
  }));
}

async function getOwnedPlan(db, userId, id) {
  const [plan] = await loadPlans(db, userId, 'pl.id = $2', [id]);
  if (!plan) throw notFound('Plan tapılmadı');
  return plan;
}

async function attachOpenTasks(db, planId, projectId) {
  await db.query(
    `INSERT INTO plan_tasks (plan_id, task_id)
     SELECT $1, t.id FROM tasks t
     WHERE t.project_id = $2 AND t.status IN ('todo', 'in_progress')
     ON CONFLICT DO NOTHING`,
    [planId, projectId],
  );
}

function validateRange(start, end, settings) {
  if (start >= end) throw badRequest('Başlama vaxtı bitmə vaxtından əvvəl olmalıdır');
  if (start < settings.work_start_min || end > settings.work_end_min) {
    throw badRequest(
      `Plan iş saatları daxilində olmalıdır (${fmt(settings.work_start_min)} - ${fmt(settings.work_end_min)})`,
    );
  }
}

function findOverlap(items) {
  const sorted = [...items].sort((a, b) => a.start_min - b.start_min);
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i].start_min < sorted[i - 1].end_min) return [sorted[i - 1], sorted[i]];
  }
  return null;
}

function assertNoOverlap(items) {
  const pair = findOverlap(items);
  if (pair) {
    throw conflict(
      `Vaxt kəsişməsi: ${fmt(pair[0].start_min)}-${fmt(pair[0].end_min)} və ${fmt(pair[1].start_min)}-${fmt(pair[1].end_min)}`,
      { code: 'OVERLAP', plan_ids: pair.map((p) => p.id) },
    );
  }
}

async function dayPlansRaw(db, userId, date) {
  const { rows } = await db.query(
    'SELECT id, start_min, end_min FROM plans WHERE user_id = $1 AND plan_date = $2 ORDER BY start_min',
    [userId, date],
  );
  return rows;
}

// GET /plans?date=YYYY-MM-DD  or  /plans?from=YYYY-MM-DD&to=YYYY-MM-DD
router.get('/', async (req, res) => {
  if (req.query.date) {
    const date = requireDate(req.query.date);
    return res.json(await loadPlans({ query }, req.userId, 'pl.plan_date = $2', [date]));
  }
  const from = requireDate(req.query.from, 'from');
  const to = requireDate(req.query.to, 'to');
  res.json(await loadPlans({ query }, req.userId, 'pl.plan_date BETWEEN $2 AND $3', [from, to]));
});

// GET /plans/current?date=YYYY-MM-DD&minute=600  — used by clients (web/mobile) for countdown & notifications.
router.get('/current', async (req, res) => {
  const now = new Date();
  const date = req.query.date
    ? requireDate(req.query.date)
    : `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  const minute =
    req.query.minute !== undefined
      ? requireInt(req.query.minute, 'minute', { min: 0, max: 1440 })
      : now.getHours() * 60 + now.getMinutes();
  const plans = await loadPlans({ query }, req.userId, 'pl.plan_date = $2', [date]);
  const current = plans.find((p) => p.start_min <= minute && minute < p.end_min) ?? null;
  const next = plans.find((p) => p.start_min > minute) ?? null;
  const settings = await getSettings(req.userId);
  res.json({
    date,
    minute,
    notify_before_min: settings.notify_before_min,
    current,
    next,
    remaining_min: current ? current.end_min - minute : null,
  });
});

router.get('/:id', async (req, res) => {
  res.json(await getOwnedPlan({ query }, req.userId, requireInt(req.params.id, 'id')));
});

router.post('/', async (req, res) => {
  const date = requireDate(req.body.date);
  const projectId = requireInt(req.body.project_id, 'project_id');
  const start = requireInt(req.body.start_min, 'start_min', { min: 0, max: 1440 });
  const end = requireInt(req.body.end_min, 'end_min', { min: 0, max: 1440 });
  const note = typeof req.body.note === 'string' ? req.body.note.trim() : '';
  await getOwnedProject(req.userId, projectId);
  validateRange(start, end, await getSettings(req.userId));

  const plan = await withTransaction(async (db) => {
    const existing = await dayPlansRaw(db, req.userId, date);
    assertNoOverlap([...existing, { id: 0, start_min: start, end_min: end }]);
    const { rows } = await db.query(
      `INSERT INTO plans (user_id, project_id, plan_date, start_min, end_min, note)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [req.userId, projectId, date, start, end, note],
    );
    await attachOpenTasks(db, rows[0].id, projectId);
    return getOwnedPlan(db, req.userId, rows[0].id);
  });
  res.status(201).json(plan);
});

/**
 * PUT /plans/:id
 * body: { start_min?, end_min?, project_id?, note?, shift_mode?: 'none' | 'next' | 'all' }
 *  - none: only this plan changes (fails with 409 if it overlaps others)
 *  - next: the following plan's start is moved to this plan's new end (its end stays)
 *  - all:  every following plan of the day is shifted by the same delta as this plan's end
 */
router.put('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const shiftMode = req.body.shift_mode ?? 'none';
  if (!SHIFT_MODES.includes(shiftMode)) throw badRequest(`shift_mode: ${SHIFT_MODES.join(', ')}`);
  const settings = await getSettings(req.userId);

  const result = await withTransaction(async (db) => {
    const current = await getOwnedPlan(db, req.userId, id);
    const start = req.body.start_min !== undefined ? requireInt(req.body.start_min, 'start_min', { min: 0, max: 1440 }) : current.start_min;
    const end = req.body.end_min !== undefined ? requireInt(req.body.end_min, 'end_min', { min: 0, max: 1440 }) : current.end_min;
    const projectId = req.body.project_id !== undefined ? requireInt(req.body.project_id, 'project_id') : current.project_id;
    const note = typeof req.body.note === 'string' ? req.body.note.trim() : current.note;
    if (projectId !== current.project_id) await getOwnedProject(req.userId, projectId);
    validateRange(start, end, settings);

    const others = (await dayPlansRaw(db, req.userId, current.plan_date)).filter((p) => p.id !== id);
    const following = others.filter((p) => p.start_min >= current.end_min).sort((a, b) => a.start_min - b.start_min);
    const delta = end - current.end_min;
    const updates = new Map();

    if (shiftMode === 'all' && delta !== 0) {
      for (const p of following) updates.set(p.id, { ...p, start_min: p.start_min + delta, end_min: p.end_min + delta });
    } else if (shiftMode === 'next' && following[0]) {
      const n = following[0];
      updates.set(n.id, { ...n, start_min: end });
    }

    for (const u of updates.values()) {
      if (u.start_min >= u.end_min) {
        throw badRequest(`Növbəti plan (${fmt(u.start_min)}-${fmt(u.end_min)}) üçün vaxt qalmır`);
      }
      if (u.start_min < settings.work_start_min || u.end_min > settings.work_end_min) {
        throw badRequest(`Sürüşdürmədən sonra plan iş saatlarından kənara çıxır (${fmt(u.start_min)}-${fmt(u.end_min)})`);
      }
    }

    const finalDay = others.map((p) => updates.get(p.id) ?? p);
    assertNoOverlap([...finalDay, { id, start_min: start, end_min: end }]);

    for (const u of updates.values()) {
      await db.query('UPDATE plans SET start_min = $2, end_min = $3 WHERE id = $1', [u.id, u.start_min, u.end_min]);
    }
    await db.query('UPDATE plans SET start_min = $2, end_min = $3, project_id = $4, note = $5 WHERE id = $1', [
      id,
      start,
      end,
      projectId,
      note,
    ]);
    if (projectId !== current.project_id) {
      await db.query('DELETE FROM plan_tasks WHERE plan_id = $1', [id]);
      await attachOpenTasks(db, id, projectId);
    }
    return { plan: await getOwnedPlan(db, req.userId, id), shifted_plan_ids: [...updates.keys()] };
  });
  res.json(result);
});

// POST /plans/:id/postpone  body: { date, start_min?, end_min? } — moves the plan to another day/time.
router.post('/:id/postpone', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const date = requireDate(req.body.date);
  const settings = await getSettings(req.userId);
  const plan = await withTransaction(async (db) => {
    const current = await getOwnedPlan(db, req.userId, id);
    const duration = current.end_min - current.start_min;
    const start = req.body.start_min !== undefined ? requireInt(req.body.start_min, 'start_min', { min: 0, max: 1440 }) : current.start_min;
    const end = req.body.end_min !== undefined ? requireInt(req.body.end_min, 'end_min', { min: 0, max: 1440 }) : start + duration;
    validateRange(start, end, settings);
    const others = (await dayPlansRaw(db, req.userId, date)).filter((p) => p.id !== id);
    assertNoOverlap([...others, { id, start_min: start, end_min: end }]);
    await db.query('UPDATE plans SET plan_date = $2, start_min = $3, end_min = $4 WHERE id = $1', [id, date, start, end]);
    await attachOpenTasks(db, id, current.project_id);
    return getOwnedPlan(db, req.userId, id);
  });
  res.json(plan);
});

// POST /plans/:id/sync-tasks — attach project tasks that were opened after the plan was created.
router.post('/:id/sync-tasks', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const current = await getOwnedPlan({ query }, req.userId, id);
  await attachOpenTasks({ query }, id, current.project_id);
  res.json(await getOwnedPlan({ query }, req.userId, id));
});

/**
 * POST /plans/generate
 * body: { source_date, target_dates: [YYYY-MM-DD], mode?: 'skip' | 'replace' }
 *  - replace: existing plans on target days are deleted before copying
 *  - skip:    copied plans that would overlap existing ones are skipped
 */
router.post('/generate', async (req, res) => {
  const sourceDate = requireDate(req.body.source_date, 'source_date');
  const mode = req.body.mode ?? 'skip';
  if (!['skip', 'replace'].includes(mode)) throw badRequest("mode: 'skip' və ya 'replace'");
  if (!Array.isArray(req.body.target_dates) || !req.body.target_dates.length) {
    throw badRequest('target_dates boş ola bilməz');
  }
  const targets = [...new Set(req.body.target_dates.map((d) => requireDate(d, 'target_dates')))].filter(
    (d) => d !== sourceDate,
  );

  const summary = await withTransaction(async (db) => {
    const { rows: source } = await db.query(
      'SELECT * FROM plans WHERE user_id = $1 AND plan_date = $2 ORDER BY start_min',
      [req.userId, sourceDate],
    );
    if (!source.length) throw badRequest('Mənbə gündə plan yoxdur');

    const result = [];
    for (const date of targets) {
      if (mode === 'replace') {
        await db.query('DELETE FROM plans WHERE user_id = $1 AND plan_date = $2', [req.userId, date]);
      }
      const existing = await dayPlansRaw(db, req.userId, date);
      let created = 0;
      let skipped = 0;
      for (const p of source) {
        if (findOverlap([...existing, p])) {
          skipped++;
          continue;
        }
        const { rows } = await db.query(
          `INSERT INTO plans (user_id, project_id, plan_date, start_min, end_min, note)
           VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, start_min, end_min`,
          [req.userId, p.project_id, date, p.start_min, p.end_min, p.note],
        );
        await attachOpenTasks(db, rows[0].id, p.project_id);
        existing.push(rows[0]);
        created++;
      }
      result.push({ date, created, skipped });
    }
    return result;
  });
  res.status(201).json({ source_date: sourceDate, mode, days: summary });
});

router.delete('/:id', async (req, res) => {
  const id = requireInt(req.params.id, 'id');
  const { rowCount } = await query('DELETE FROM plans WHERE id = $1 AND user_id = $2', [id, req.userId]);
  if (!rowCount) throw notFound('Plan tapılmadı');
  res.status(204).end();
});

export default router;
