import { t, tm } from '../i18n';

export const pad = (n) => String(n).padStart(2, '0');

export const fmtMin = (m) => `${pad(Math.floor(m / 60))}:${pad(m % 60)}`;

export function fmtDuration(min) {
  const h = Math.floor(min / 60);
  const m = min % 60;
  if (!h) return t('time.minutes', { m });
  return m ? t('time.hoursMinutes', { h, m }) : t('time.hours', { h });
}

export function fmtSeconds(sec) {
  const s = Math.max(0, Math.floor(sec));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return h ? `${h}:${pad(m)}:${pad(s % 60)}` : `${pad(m)}:${pad(s % 60)}`;
}

export const toDateStr = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

export const todayStr = () => toDateStr(new Date());

export function parseDate(s) {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(y, m - 1, d);
}

export function addDays(s, n) {
  const d = parseDate(s);
  d.setDate(d.getDate() + n);
  return toDateStr(d);
}

export const weekdayIndex = (s) => (parseDate(s).getDay() + 6) % 7;

export function weekDates(s) {
  const monday = addDays(s, -weekdayIndex(s));
  return Array.from({ length: 7 }, (_, i) => addDays(monday, i));
}

export const weekdayShort = (s) => tm('time.weekdaysShort')[weekdayIndex(s)];

export function fmtDateLong(s) {
  const d = parseDate(s);
  return t('time.dateLong', {
    day: d.getDate(),
    month: tm('time.months')[d.getMonth()],
    year: d.getFullYear(),
    weekday: tm('time.weekdays')[weekdayIndex(s)],
  });
}
