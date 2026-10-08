import { parseDate } from './time';

// localStorage key of the plan whose timer was started in this browser; idle auto-pause only applies to it.
export const DEVICE_PLAN_KEY = 'tracking-device-plan';

export function planWindow(plan) {
  const day = parseDate(plan.plan_date).getTime();
  return { start: day + plan.start_min * 60000, end: day + plan.end_min * 60000 };
}

/**
 * Live tracking numbers. Server values are a snapshot taken at `loadedAt` (client ms);
 * the running session / ongoing break grows with the time elapsed since then.
 */
export function liveTracking(plan, nowMs, loadedAt) {
  const tr = plan.tracking;
  const elapsed = Math.max(0, (nowMs - loadedAt) / 1000);
  const currentBreak = tr.state === 'paused' ? tr.current_break_sec + elapsed : 0;
  return {
    state: tr.state,
    effective: tr.effective_sec + (tr.state === 'running' ? elapsed : 0),
    currentBreak,
    breaks: tr.break_sec + currentBreak,
  };
}

/** Seconds of the plan that have already passed (efficiency is measured against this). */
export function elapsedPlanSec(plan, nowMs) {
  const { start, end } = planWindow(plan);
  return Math.max(0, (Math.min(nowMs, end) - start) / 1000);
}

export function efficiencyPct(effectiveSec, baseSec) {
  return baseSec > 0 ? Math.round((effectiveSec / baseSec) * 100) : null;
}
