// End of a plan as an absolute timestamp, using the user's time zone (expects aliases `pl` and `s`).
export const PLAN_END_SQL = `((pl.plan_date::timestamp + pl.end_min * interval '1 minute') AT TIME ZONE s.timezone)`;

/** Closes running sessions whose plan has already ended (when the user has auto_stop enabled). */
export async function closeExpiredSessions(db, userId) {
  await db.query(
    `UPDATE work_sessions ws
     SET ended_at = GREATEST(ws.started_at, ${PLAN_END_SQL}), end_reason = 'auto_stop'
     FROM plans pl, user_settings s
     WHERE ws.user_id = $1 AND ws.ended_at IS NULL
       AND pl.id = ws.plan_id AND s.user_id = ws.user_id
       AND s.auto_stop AND ${PLAN_END_SQL} <= now()`,
    [userId],
  );
}

/**
 * Tracking summary per plan:
 *  state: not_started | running | paused | stopped (auto-stopped at plan end)
 *  effective_sec: total worked time (running session counted up to now)
 *  break_sec: total of finished gaps between sessions
 *  current_break_sec: length of the ongoing pause (state = paused)
 */
export async function loadTracking(db, planIds) {
  const { rows } = await db.query(
    `SELECT plan_id, started_at, ended_at, end_reason,
       EXTRACT(EPOCH FROM COALESCE(ended_at, now()) - started_at)::float AS sec,
       EXTRACT(EPOCH FROM now() - ended_at)::float AS since_end
     FROM work_sessions WHERE plan_id = ANY($1::int[])
     ORDER BY started_at`,
    [planIds],
  );
  const byPlan = new Map(planIds.map((id) => [id, []]));
  rows.forEach((r) => byPlan.get(r.plan_id).push(r));
  return new Map([...byPlan].map(([id, sessions]) => [id, summarize(sessions)]));
}

function summarize(sessions) {
  if (!sessions.length) {
    return { state: 'not_started', effective_sec: 0, break_sec: 0, current_break_sec: 0, sessions: [] };
  }
  const last = sessions.at(-1);
  let breakMs = 0;
  for (let i = 1; i < sessions.length; i++) breakMs += sessions[i].started_at - sessions[i - 1].ended_at;
  const state = !last.ended_at ? 'running' : last.end_reason === 'auto_stop' ? 'stopped' : 'paused';
  return {
    state,
    effective_sec: Math.round(sessions.reduce((s, x) => s + x.sec, 0)),
    break_sec: Math.round(breakMs / 1000),
    current_break_sec: state === 'paused' ? Math.round(last.since_end) : 0,
    sessions: sessions.map(({ started_at, ended_at, end_reason }) => ({ started_at, ended_at, end_reason })),
  };
}
