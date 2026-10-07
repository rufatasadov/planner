import api from '../api';
import { useToast } from '../stores/toast';
import { fmtMin, toDateStr } from '../utils/time';
import { t } from '../i18n';

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

export function useNotifier() {
  let data = null;
  let fetchTimer = null;
  let tickTimer = null;

  async function refresh() {
    const d = new Date();
    try {
      const res = await api.get('/plans/current', {
        params: { date: toDateStr(d), minute: d.getHours() * 60 + d.getMinutes() },
      });
      data = res.data;
    } catch {
      data = null;
    }
  }

  function check() {
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
  }

  function stop() {
    clearInterval(fetchTimer);
    clearInterval(tickTimer);
    window.removeEventListener('plans-changed', refresh);
  }

  return { start, stop };
}
