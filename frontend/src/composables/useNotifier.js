import api from '../api';
import { useToast } from '../stores/toast';
import { fmtMin, toDateStr } from '../utils/time';
import { t } from '../i18n';
import { DEVICE_PLAN_KEY } from '../utils/tracking';

export function beep() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    [0, 0.25].forEach((offset) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.frequency.value = 880;
      gain.gain.setValueAtTime(0.15, ctx.currentTime + offset);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + offset + 0.2);
      osc.connect(gain).connect(ctx.destination);
      osc.start(ctx.currentTime + offset);
      osc.stop(ctx.currentTime + offset + 0.2);
    });
  } catch {
    /* audio not available */
  }
}

export function showNotification(title, body) {
  useToast().push({ type: 'warning', title, body, timeout: 15000 });
  beep();
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, { body });
  }
}

export const idleSupported = () => 'IdleDetector' in window;

/** 'granted' | 'denied' | 'prompt' | 'unsupported' */
export async function idlePermissionState() {
  if (!idleSupported()) return 'unsupported';
  try {
    return (await navigator.permissions.query({ name: 'idle-detection' })).state;
  } catch {
    return 'prompt';
  }
}

export async function requestIdlePermission() {
  if (!idleSupported()) return 'unsupported';
  try {
    const state = await window.IdleDetector.requestPermission();
    window.dispatchEvent(new Event('plans-changed'));
    return state;
  } catch {
    return 'denied';
  }
}

export function useNotifier() {
  let data = null;
  let fetchedAt = 0;
  let fetchTimer = null;
  let tickTimer = null;
  let idleAbort = null;
  let idleThreshold = null;

  async function refresh() {
    const d = new Date();
    try {
      const res = await api.get('/plans/current', {
        params: { date: toDateStr(d), minute: d.getHours() * 60 + d.getMinutes() },
      });
      data = res.data;
      fetchedAt = Date.now();
    } catch {
      data = null;
    }
    syncIdle();
  }

  // System-wide idle detection (Chrome/Edge): pauses the timer started in this browser when the user is away.
  let idleQueue = Promise.resolve();
  function syncIdle() {
    idleQueue = idleQueue.then(applyIdle, applyIdle);
  }

  async function applyIdle() {
    const min = data?.idle_pause_min ?? 0;
    const threshold = Math.max(60000, min * 60000);
    if (!min || (await idlePermissionState()) !== 'granted') return stopIdle();
    if (idleAbort && idleThreshold === threshold) return;
    stopIdle();
    const abort = new AbortController();
    const detector = new window.IdleDetector();
    detector.addEventListener('change', () => detector.userState === 'idle' && onIdle(threshold));
    try {
      await detector.start({ threshold, signal: abort.signal });
      idleAbort = abort;
      idleThreshold = threshold;
    } catch {
      /* permission revoked or not a secure context */
    }
  }

  function stopIdle() {
    idleAbort?.abort();
    idleAbort = null;
    idleThreshold = null;
  }

  async function onIdle(threshold) {
    await refresh();
    const plan = data?.running;
    if (!plan || localStorage.getItem(DEVICE_PLAN_KEY) !== String(plan.id)) return;
    try {
      await api.post(`/plans/${plan.id}/tracking/pause`, {
        reason: 'idle',
        at: new Date(Date.now() - threshold).toISOString(),
      });
      showNotification(
        t('tracking.idlePausedTitle', { name: plan.project_name }),
        t('tracking.idlePausedBody', { m: Math.round(threshold / 60000) }),
      );
      window.dispatchEvent(new Event('tracking-changed'));
      refresh();
    } catch {
      /* will retry on the next idle event */
    }
  }

  function checkBreak() {
    const plan = data?.current;
    if (!plan || plan.tracking.state !== 'paused' || !data.break_reminder_min) return;
    const breakSec = plan.tracking.current_break_sec + (Date.now() - fetchedAt) / 1000;
    if (breakSec < data.break_reminder_min * 60) return;
    const key = `break-notified:${plan.id}:${plan.tracking.sessions.length}`;
    if (localStorage.getItem(key)) return;
    localStorage.setItem(key, '1');
    showNotification(
      t('tracking.breakReminderTitle', { m: Math.floor(breakSec / 60) }),
      t('tracking.breakReminderBody', { name: plan.project_name }),
    );
  }

  function check() {
    checkBreak();
    const plan = data?.current;
    if (!plan) return;
    const d = new Date();
    if (toDateStr(d) !== data.date) return;
    const nowSec = d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds();
    const remaining = plan.end_min * 60 - nowSec;
    if (remaining <= 0) return refresh();
    if (remaining > data.notify_before_min * 60) return;

    const key = `notified:${data.date}:${plan.id}:${plan.end_min}`;
    if (localStorage.getItem(key)) return;
    localStorage.setItem(key, '1');

    const range = `${fmtMin(plan.start_min)}-${fmtMin(plan.end_min)}`;
    const next = data.next
      ? ' ' + t('notify.next', { name: data.next.project_name, time: fmtMin(data.next.start_min) })
      : '';
    showNotification(
      t('notify.title', { name: plan.project_name, m: Math.ceil(remaining / 60) }),
      t('notify.body', { range }) + next,
    );
  }

  function start() {
    stop();
    refresh();
    fetchTimer = setInterval(refresh, 30000);
    tickTimer = setInterval(check, 5000);
    window.addEventListener('plans-changed', refresh);
    window.addEventListener('tracking-changed', refresh);
  }

  function stop() {
    clearInterval(fetchTimer);
    clearInterval(tickTimer);
    stopIdle();
    window.removeEventListener('plans-changed', refresh);
    window.removeEventListener('tracking-changed', refresh);
  }

  return { start, stop };
}
