<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import api, { errMsg } from '../api';
import { useAuthStore } from '../stores/auth';
import { useToast } from '../stores/toast';
import { t } from '../i18n';
import { fmtAgo, fmtDateShort, fmtDuration, fmtMin, parseDate, weekdayShort } from '../utils/time';
import { STATUSES } from '../utils/status';
import DonutChart from '../components/DonutChart.vue';

const auth = useAuthStore();
const toast = useToast();

const PERIODS = [7, 30, 90, 365];
const METRICS = ['active_users', 'new_users', 'tasks_created', 'tasks_done', 'plans', 'tracked_sec'];

const days = ref(Number(localStorage.getItem('admin-days')) || 30);
const data = ref(null);
const loading = ref(false);
const metric = ref('active_users');
const search = ref('');
const sortKey = ref('activity_pct');
const sortDir = ref(-1);

async function load() {
  loading.value = true;
  try {
    const res = await api.get('/admin/stats', { params: { days: days.value } });
    data.value = res.data;
  } catch (e) {
    toast.error(t('admin.loadFailed'), errMsg(e));
  } finally {
    loading.value = false;
  }
}

watch(days, (d) => {
  localStorage.setItem('admin-days', String(d));
  load();
});
onMounted(load);

const ov = computed(() => data.value?.overview);
const hours = (sec) => fmtDuration(Math.round(sec / 60));
const pct = (v) => (v === null || v === undefined ? '—' : `${v}%`);

const kpis = computed(() => {
  const o = ov.value;
  if (!o) return [];
  return [
    { icon: '👥', label: t('admin.kpi.users'), value: o.users, sub: t('admin.kpi.newUsers', { n: o.new_users }) },
    {
      icon: '⚡',
      label: t('admin.kpi.active'),
      value: o.active_users_period,
      sub: t('admin.kpi.activeSub', { w: o.active_users_7d, d: o.active_users_24h }),
    },
    { icon: '🟢', label: t('admin.kpi.online'), value: o.online_now, sub: t('admin.kpi.onlineSub') },
    { icon: '📈', label: t('admin.kpi.activity'), value: `${o.avg_activity_pct}%`, sub: t('admin.kpi.activitySub'), bar: o.avg_activity_pct },
    {
      icon: '✅',
      label: t('admin.kpi.tasks'),
      value: o.tasks,
      sub: t('admin.kpi.tasksSub', { n: o.tasks_created_period, d: o.tasks_done_period }),
    },
    { icon: '🎯', label: t('admin.kpi.completion'), value: pct(o.completion_pct), sub: t('admin.kpi.completionSub'), bar: o.completion_pct },
    { icon: '📅', label: t('admin.kpi.plans'), value: o.plans, sub: t('admin.kpi.plansSub', { n: o.plans_period }) },
    {
      icon: '⏱️',
      label: t('admin.kpi.tracked'),
      value: hours(o.tracked_sec_period),
      sub: t('admin.kpi.trackedSub', { total: hours(o.tracked_sec) }),
    },
    { icon: '🏁', label: t('admin.kpi.execution'), value: pct(o.execution_pct), sub: t('admin.kpi.executionSub'), bar: o.execution_pct },
    { icon: '📝', label: t('admin.kpi.notes'), value: o.notes, sub: t('admin.kpi.notesSub', { n: o.notes_period }) },
  ];
});

const statusSegments = computed(() =>
  ov.value
    ? STATUSES.map((s) => ({ label: t(`status.${s.value}`), color: s.color, value: ov.value.tasks_by_status[s.value] }))
    : [],
);

// ---------- Daily chart ----------
const CHART_H = 160;
const series = computed(() => {
  const list = data.value?.daily ?? [];
  const toValue = (d) => (metric.value === 'tracked_sec' ? +(d.tracked_sec / 3600).toFixed(1) : d[metric.value]);
  return list.map((d) => ({ date: d.date, value: toValue(d) }));
});
const seriesMax = computed(() => Math.max(1, ...series.value.map((d) => d.value)));
const seriesTotal = computed(() => {
  const total = series.value.reduce((s, d) => s + d.value, 0);
  return metric.value === 'tracked_sec' ? total.toFixed(1) : total;
});
const axisLabels = computed(() => {
  const list = series.value;
  if (!list.length) return [];
  const idx = [...new Set([0, Math.floor((list.length - 1) / 2), list.length - 1])];
  return idx.map((i) => ({ i, label: fmtDateShort(parseDate(list[i].date)) }));
});

// ---------- Users table ----------
const COLUMNS = [
  { key: 'name', label: 'admin.col.user', sort: (u) => u.name.toLowerCase() },
  { key: 'created_at', label: 'admin.col.registered', sort: (u) => u.created_at },
  { key: 'last_activity', label: 'admin.col.lastActivity', sort: (u) => u.last_activity ?? '' },
  { key: 'projects', label: 'admin.col.projects', num: true },
  { key: 'tasks', label: 'admin.col.tasks', num: true },
  { key: 'completion_pct', label: 'admin.col.completion', num: true, sort: (u) => u.completion_pct ?? -1 },
  { key: 'plans', label: 'admin.col.plans', num: true },
  { key: 'tracked_sec_period', label: 'admin.col.tracked', num: true },
  { key: 'execution_pct', label: 'admin.col.execution', num: true, sort: (u) => u.execution_pct ?? -1 },
  { key: 'notes', label: 'admin.col.notes', num: true },
  { key: 'activity_pct', label: 'admin.col.activity', num: true },
];

function setSort(col) {
  if (sortKey.value === col.key) sortDir.value = -sortDir.value;
  else {
    sortKey.value = col.key;
    sortDir.value = col.key === 'name' ? 1 : -1;
  }
}

const users = computed(() => {
  const q = search.value.trim().toLowerCase();
  const col = COLUMNS.find((c) => c.key === sortKey.value);
  const get = col.sort ?? ((u) => u[col.key]);
  return (data.value?.users ?? [])
    .filter((u) => !q || u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q))
    .sort((a, b) => {
      const x = get(a);
      const y = get(b);
      return (x < y ? -1 : x > y ? 1 : 0) * sortDir.value;
    });
});

const ago = (ts) => (ts ? fmtAgo(ts) : t('admin.never'));
const fmtTime = (ts) => {
  const d = new Date(ts);
  return fmtMin(d.getHours() * 60 + d.getMinutes());
};
const level = (v) => (v === null ? '' : v >= 70 ? 'good' : v >= 35 ? 'mid' : 'low');
</script>

<template>
  <div class="admin-page">
    <section class="page-head">
      <div>
        <h1>🛡️ {{ t('admin.title') }}</h1>
        <div class="muted small">
          {{ t('admin.subtitle') }}
          <template v-if="data"> · {{ t('admin.updatedAt', { time: fmtTime(data.generated_at) }) }}</template>
        </div>
      </div>
      <div class="head-actions">
        <div class="tabs inline admin-periods">
          <button v-for="p in PERIODS" :key="p" :class="{ active: days === p }" @click="days = p">
            {{ t(`admin.periods.${p}`) }}
          </button>
        </div>
        <button class="btn ghost" :disabled="loading" @click="load">⟳ {{ t('admin.refresh') }}</button>
      </div>
    </section>

    <template v-if="data">
      <section class="kpi-grid">
        <div v-for="k in kpis" :key="k.label" class="card kpi">
          <div class="kpi-head">
            <span class="kpi-icon">{{ k.icon }}</span>
            <span class="muted small">{{ k.label }}</span>
          </div>
          <b class="kpi-value">{{ k.value }}</b>
          <div v-if="k.bar !== undefined" class="mini-bar" :class="level(k.bar)">
            <div :style="{ width: Math.min(k.bar ?? 0, 100) + '%' }"></div>
          </div>
          <span class="muted small">{{ k.sub }}</span>
        </div>
      </section>

      <div class="admin-charts">
        <section class="card">
          <div class="card-head">
            <h3>{{ t('admin.chart.title') }}</h3>
            <span class="muted small">{{ t('admin.chart.total', { v: seriesTotal }) }}</span>
          </div>
          <div class="chips metric-chips">
            <button
              v-for="m in METRICS"
              :key="m"
              class="chip"
              :class="{ active: metric === m }"
              @click="metric = m"
            >
              {{ t(`admin.chart.${m}`) }}
            </button>
          </div>
          <div class="bar-chart">
            <div class="bc-max muted small">{{ seriesMax }}</div>
            <svg :viewBox="`0 0 ${series.length * 10} ${CHART_H}`" preserveAspectRatio="none">
              <line x1="0" :x2="series.length * 10" :y1="CHART_H / 2" :y2="CHART_H / 2" class="bc-grid" />
              <rect
                v-for="(d, i) in series"
                :key="d.date"
                class="bc-bar"
                :x="i * 10 + 1.5"
                :y="CHART_H - (d.value / seriesMax) * (CHART_H - 4)"
                width="7"
                :height="Math.max(d.value ? 2 : 0, (d.value / seriesMax) * (CHART_H - 4))"
                rx="1.5"
              >
                <title>{{ weekdayShort(d.date) }} {{ fmtDateShort(parseDate(d.date)) }}: {{ d.value }}</title>
              </rect>
            </svg>
            <div class="bc-axis muted small">
              <span
                v-for="a in axisLabels"
                :key="a.i"
                :style="{ left: ((a.i + 0.5) / series.length) * 100 + '%' }"
              >{{ a.label }}</span>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card-head"><h3>{{ t('admin.statusTitle') }}</h3></div>
          <DonutChart :segments="statusSegments" :center-title="String(ov.tasks)" :center-sub="t('admin.kpi.tasks')" />
        </section>
      </div>

      <section class="card">
        <div class="card-head users-head">
          <h3>{{ t('admin.usersTitle') }} <span class="muted">({{ users.length }})</span></h3>
          <input v-model="search" type="search" class="admin-search" :placeholder="t('admin.search')" />
        </div>
        <div class="table-scroll">
          <table class="admin-table">
            <thead>
              <tr>
                <th
                  v-for="c in COLUMNS"
                  :key="c.key"
                  :class="{ num: c.num, sorted: sortKey === c.key }"
                  @click="setSort(c)"
                >
                  {{ t(c.label) }}
                  <span class="sort-ind">{{ sortKey === c.key ? (sortDir > 0 ? '▲' : '▼') : '' }}</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="u in users" :key="u.id">
                <td>
                  <div class="au-user">
                    <span class="avatar sm">{{ u.name[0]?.toUpperCase() }}</span>
                    <div class="au-names">
                      <b>
                        {{ u.name }}
                        <span v-if="u.tracking_now" class="online-dot" :title="t('admin.online')"></span>
                        <small v-if="u.id === auth.user?.id" class="muted">({{ t('admin.you') }})</small>
                      </b>
                      <span class="muted small">{{ u.email }}</span>
                    </div>
                  </div>
                </td>
                <td class="nowrap">{{ fmtDateShort(u.created_at, { year: true }) }}</td>
                <td class="nowrap" :title="u.last_seen_at ? t('admin.lastSeen', { time: ago(u.last_seen_at) }) : ''">
                  {{ ago(u.last_activity) }}
                  <div v-if="u.last_seen_at" class="muted small">👁 {{ ago(u.last_seen_at) }}</div>
                </td>
                <td class="num">{{ u.projects }}</td>
                <td
                  class="num"
                  :title="t('admin.tasksHint', { done: u.tasks_done, open: u.tasks_todo + u.tasks_in_progress, subs: u.subtasks })"
                >
                  <b>{{ u.tasks }}</b>
                  <div class="muted small">✓ {{ u.tasks_done }}</div>
                </td>
                <td class="num"><span class="pct" :class="level(u.completion_pct)">{{ pct(u.completion_pct) }}</span></td>
                <td class="num">
                  {{ u.plans }}
                  <div class="muted small">+{{ u.plans_period }}</div>
                </td>
                <td
                  class="num nowrap"
                  :title="t('admin.trackedHint', { period: hours(u.tracked_sec_period), total: hours(u.tracked_sec) })"
                >
                  {{ hours(u.tracked_sec_period) }}
                </td>
                <td class="num"><span class="pct" :class="level(u.execution_pct)">{{ pct(u.execution_pct) }}</span></td>
                <td class="num">{{ u.notes }}</td>
                <td
                  class="num"
                  :title="t('admin.activityHint', { active: u.active_days, days: u.period_days, actions: u.actions_period })"
                >
                  <div class="activity-cell">
                    <div class="mini-bar" :class="level(u.activity_pct)">
                      <div :style="{ width: u.activity_pct + '%' }"></div>
                    </div>
                    <b>{{ u.activity_pct }}%</b>
                  </div>
                  <div class="muted small">{{ u.active_days }}/{{ u.period_days }}</div>
                </td>
              </tr>
              <tr v-if="!users.length">
                <td :colspan="COLUMNS.length" class="muted empty-row">{{ t('admin.noUsers') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
    <div v-else-if="loading" class="muted empty">…</div>
  </div>
</template>
