<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api, { errMsg, notifyPlansChanged } from '../api';
import { useSettingsStore } from '../stores/settings';
import { useToast } from '../stores/toast';
import { useNow } from '../composables/useNow';
import { t } from '../i18n';
import {
  addDays, fmtDateLong, fmtDuration, fmtMin, fmtSeconds, parseDate, toDateStr, weekDates, weekdayShort,
} from '../utils/time';
import DayTimeline from '../components/DayTimeline.vue';
import DonutChart from '../components/DonutChart.vue';
import CountdownRing from '../components/CountdownRing.vue';
import TaskStatusSelect from '../components/TaskStatusSelect.vue';
import PlanFormModal from '../components/PlanFormModal.vue';
import ShiftChoiceModal from '../components/ShiftChoiceModal.vue';
import PostponeModal from '../components/PostponeModal.vue';
import GenerateModal from '../components/GenerateModal.vue';
import TrackingPanel from '../components/TrackingPanel.vue';
import TaskNotesModal from '../components/TaskNotesModal.vue';
import AppModal from '../components/AppModal.vue';
import { buildTree } from '../utils/tasks';
import { DEVICE_PLAN_KEY, efficiencyPct, elapsedPlanSec, liveTracking } from '../utils/tracking';

const route = useRoute();
const router = useRouter();
const settings = useSettingsStore();
const toast = useToast();
const now = useNow();

const date = ref(typeof route.query.date === 'string' ? route.query.date : toDateStr(new Date()));
const weekPlans = ref([]);
const projects = ref([]);
const loading = ref(false);
const saving = ref(false);
const selectedId = ref(null);
const loadedAt = ref(Date.now());
const trackingBusy = ref(false);

const formOpen = ref(false);
const editing = ref(null);
const formDefaults = ref({});
const shiftState = ref(null); // { plan, form, delta, following }
const postponing = ref(null);
const generateOpen = ref(false);
const notesTask = ref(null);
const notesPlanId = ref(null);
const pendingMove = ref(null); // { plan, start_min, end_min } from timeline drag, awaiting confirmation

const week = computed(() => weekDates(date.value));
const plans = computed(() => weekPlans.value.filter((p) => p.plan_date === date.value));

const todayStr = computed(() => toDateStr(now.value));
const isToday = computed(() => date.value === todayStr.value);
const nowMin = computed(() => now.value.getHours() * 60 + now.value.getMinutes());
const nowSec = computed(() => nowMin.value * 60 + now.value.getSeconds());
const nowMs = computed(() => now.value.getTime());

const currentPlan = computed(() =>
  isToday.value ? plans.value.find((p) => p.start_min <= nowMin.value && nowMin.value < p.end_min) ?? null : null,
);
const nextPlan = computed(() => (isToday.value ? plans.value.find((p) => p.start_min > nowMin.value) ?? null : null));
const selected = computed(
  () => plans.value.find((p) => p.id === selectedId.value) ?? currentPlan.value ?? plans.value[0] ?? null,
);

const COLLAPSED_KEY = 'plan-collapsed-tasks';
const collapsedTasks = ref(new Set(JSON.parse(localStorage.getItem(COLLAPSED_KEY) || '[]')));

function toggleTask(task) {
  const next = new Set(collapsedTasks.value);
  next.has(task.id) ? next.delete(task.id) : next.add(task.id);
  collapsedTasks.value = next;
  localStorage.setItem(COLLAPSED_KEY, JSON.stringify([...next]));
}

const selectedRows = computed(() =>
  selected.value
    ? buildTree(selected.value.tasks).flatMap(({ task, children }) => [
        { task, sub: false, childCount: children.length },
        ...(collapsedTasks.value.has(task.id) ? [] : children.map((child) => ({ task: child, sub: true }))),
      ])
    : [],
);
const hasSubtaskRows = computed(() => selectedRows.value.some((r) => r.childCount));

const workDay = computed(() => settings.work_end_min - settings.work_start_min);
const plannedMin = computed(() => plans.value.reduce((s, p) => s + p.end_min - p.start_min, 0));
const dayTasks = computed(() => {
  const map = new Map();
  plans.value.forEach((p) => p.tasks.forEach((task) => map.set(task.id, task)));
  return [...map.values()];
});
const doneTasks = computed(() => dayTasks.value.filter((task) => task.status === 'done').length);
const dayProgress = computed(() => {
  if (date.value < todayStr.value) return 100;
  if (date.value > todayStr.value) return 0;
  const p = ((nowMin.value - settings.work_start_min) / workDay.value) * 100;
  return Math.min(100, Math.max(0, p));
});

const planTracking = computed(() =>
  Object.fromEntries(
    plans.value.map((p) => {
      const live = liveTracking(p, nowMs.value, loadedAt.value);
      const base = elapsedPlanSec(p, nowMs.value);
      return [p.id, { ...live, base, pct: efficiencyPct(live.effective, base) }];
    }),
  ),
);
const dayEffective = computed(() => Object.values(planTracking.value).reduce((s, x) => s + x.effective, 0));
const dayBreaks = computed(() => Object.values(planTracking.value).reduce((s, x) => s + x.breaks, 0));
const dayEfficiency = computed(() =>
  efficiencyPct(dayEffective.value, Object.values(planTracking.value).reduce((s, x) => s + x.base, 0)),
);
const dayEffLevel = computed(() => {
  if (dayEfficiency.value === null) return '';
  const target = settings.target_efficiency_pct;
  return dayEfficiency.value >= target ? 'good' : dayEfficiency.value >= target * 0.75 ? 'mid' : 'low';
});

const segments = computed(() => {
  const map = new Map();
  for (const p of plans.value) {
    const s = map.get(p.project_id) ?? { label: p.project_name, color: p.project_color, value: 0 };
    s.value += p.end_min - p.start_min;
    map.set(p.project_id, s);
  }
  const list = [...map.values()].sort((a, b) => b.value - a.value);
  const free = workDay.value - plannedMin.value;
  if (free > 0) list.push({ label: t('plan.freeTime'), color: 'var(--free)', value: free });
  return list;
});

const countdown = computed(() => {
  if (currentPlan.value) {
    const p = currentPlan.value;
    const remaining = p.end_min * 60 - nowSec.value;
    return {
      total: (p.end_min - p.start_min) * 60,
      remaining,
      color: p.project_color,
      caption: t('plan.left'),
      warning: remaining <= settings.notify_before_min * 60,
    };
  }
  if (nextPlan.value) {
    const p = nextPlan.value;
    const prevEnd = plans.value.filter((x) => x.end_min <= p.start_min).at(-1)?.end_min ?? settings.work_start_min;
    return {
      total: Math.max(1, (p.start_min - Math.min(prevEnd, nowMin.value)) * 60),
      remaining: p.start_min * 60 - nowSec.value,
      color: 'var(--muted)',
      caption: t('plan.untilStart'),
      warning: false,
    };
  }
  return null;
});

const weekSummary = computed(() =>
  week.value.map((d) => {
    const items = weekPlans.value.filter((p) => p.plan_date === d);
    return { date: d, items, minutes: items.reduce((s, p) => s + p.end_min - p.start_min, 0) };
  }),
);

async function load() {
  loading.value = true;
  try {
    await settings.load();
    const [plansRes, projectsRes] = await Promise.all([
      api.get('/plans', { params: { from: week.value[0], to: week.value[6] } }),
      api.get('/projects'),
    ]);
    weekPlans.value = plansRes.data;
    projects.value = projectsRes.data;
    loadedAt.value = Date.now();
  } catch (e) {
    toast.error(t('common.loadFailed'), errMsg(e));
  } finally {
    loading.value = false;
  }
}

watch(date, (d) => {
  selectedId.value = null;
  router.replace({ query: d === todayStr.value ? {} : { date: d } });
  load();
});
// Reload when a plan ends so the server can auto-stop its timer.
watch(nowMin, (m, prev) => {
  if (isToday.value && plans.value.some((p) => p.end_min > prev && p.end_min <= m)) load();
});

onMounted(() => {
  load();
  window.addEventListener('tracking-changed', load);
});
onUnmounted(() => window.removeEventListener('tracking-changed', load));

async function startTracking(plan) {
  trackingBusy.value = true;
  try {
    await api.post(`/plans/${plan.id}/tracking/start`);
    localStorage.setItem(DEVICE_PLAN_KEY, String(plan.id));
    await afterChange();
  } catch (e) {
    toast.error(t('tracking.failed'), errMsg(e));
  } finally {
    trackingBusy.value = false;
  }
}

async function pauseTracking(plan) {
  trackingBusy.value = true;
  try {
    await api.post(`/plans/${plan.id}/tracking/pause`);
    await afterChange();
  } catch (e) {
    toast.error(t('tracking.failed'), errMsg(e));
  } finally {
    trackingBusy.value = false;
  }
}

function freeSlotFrom(start) {
  let s = Math.max(start, settings.work_start_min);
  for (const p of plans.value) if (p.start_min <= s && s < p.end_min) s = p.end_min;
  const nextStart = plans.value.find((p) => p.start_min > s)?.start_min ?? settings.work_end_min;
  return { start_min: s, end_min: Math.min(s + 60, nextStart, settings.work_end_min) };
}

function openCreate(start) {
  if (!projects.value.length) {
    toast.push({ type: 'info', title: t('plan.createProjectFirst') });
    return router.push('/projects');
  }
  const base = start ?? (isToday.value ? Math.ceil(nowMin.value / 15) * 15 : settings.work_start_min);
  const slot = freeSlotFrom(base);
  if (slot.start_min >= settings.work_end_min) return toast.error(t('plan.noFreeTime'), t('plan.dayFull'));
  editing.value = null;
  formDefaults.value = slot;
  formOpen.value = true;
}

function openEdit(plan) {
  editing.value = plan;
  formOpen.value = true;
}

async function savePlan(form) {
  if (!editing.value) {
    saving.value = true;
    try {
      const { data } = await api.post('/plans', { ...form, date: date.value });
      formOpen.value = false;
      selectedId.value = data.id;
      toast.success(t('plan.created'), t('plan.tasksAdded', { n: data.tasks.length }));
      await afterChange();
    } catch (e) {
      toast.error(t('plan.createFailed'), errMsg(e));
    } finally {
      saving.value = false;
    }
    return;
  }
  const plan = editing.value;
  const delta = form.end_min - plan.end_min;
  const following = plans.value.filter((p) => p.id !== plan.id && p.start_min >= plan.end_min);
  if (delta !== 0 && following.length) {
    formOpen.value = false;
    shiftState.value = { plan, form, delta, following };
    return;
  }
  await updatePlan(plan.id, form, 'none');
}

async function updatePlan(id, form, shiftMode) {
  saving.value = true;
  try {
    const { data } = await api.put(`/plans/${id}`, { ...form, shift_mode: shiftMode });
    formOpen.value = false;
    shiftState.value = null;
    const n = data.shifted_plan_ids.length;
    toast.success(t('plan.updated'), n ? t('plan.shiftedCount', { n }) : '');
    await afterChange();
  } catch (e) {
    toast.error(t('plan.updateFailed'), errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function confirmMove() {
  const { plan, start_min, end_min } = pendingMove.value;
  saving.value = true;
  try {
    await api.put(`/plans/${plan.id}`, { start_min, end_min, shift_mode: 'none' });
    toast.success(t('plan.updated'), `${plan.project_name}: ${fmtMin(start_min)} – ${fmtMin(end_min)}`);
    await afterChange();
  } catch (e) {
    toast.error(t('plan.updateFailed'), errMsg(e));
  } finally {
    pendingMove.value = null;
    saving.value = false;
  }
}

async function deletePlan(plan) {
  const range = `${fmtMin(plan.start_min)}-${fmtMin(plan.end_min)}`;
  if (!confirm(t('plan.confirmDelete', { name: plan.project_name, range }))) return;
  try {
    await api.delete(`/plans/${plan.id}`);
    toast.success(t('plan.deleted'));
    selectedId.value = null;
    await afterChange();
  } catch (e) {
    toast.error(t('common.deleteFailed'), errMsg(e));
  }
}

async function postpone(payload) {
  saving.value = true;
  try {
    await api.post(`/plans/${postponing.value.id}/postpone`, payload);
    toast.success(t('plan.postponed'), `${fmtDateLong(payload.date)}, ${fmtMin(payload.start_min)}`);
    postponing.value = null;
    selectedId.value = null;
    await afterChange();
  } catch (e) {
    toast.error(t('plan.postponeFailed'), errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function syncTasks(plan) {
  try {
    const { data } = await api.post(`/plans/${plan.id}/sync-tasks`);
    const added = data.tasks.length - plan.tasks.length;
    toast.success(added ? t('plan.newTasksAdded', { n: added }) : t('plan.noNewTasks'));
    await load();
  } catch (e) {
    toast.error(t('common.error'), errMsg(e));
  }
}

async function generate(payload) {
  saving.value = true;
  try {
    const { data } = await api.post('/plans/generate', { source_date: date.value, ...payload });
    const created = data.days.reduce((s, d) => s + d.created, 0);
    const skipped = data.days.reduce((s, d) => s + d.skipped, 0);
    toast.success(t('generate.created', { n: created }), skipped ? t('generate.skipped', { n: skipped }) : '');
    generateOpen.value = false;
    await afterChange();
  } catch (e) {
    toast.error(t('generate.failed'), errMsg(e));
  } finally {
    saving.value = false;
  }
}

async function setTaskStatus(task, status) {
  const prev = task.status;
  const apply = (s) => weekPlans.value.forEach((p) => p.tasks.forEach((x) => x.id === task.id && (x.status = s)));
  apply(status);
  try {
    const { data } = await api.patch(`/tasks/${task.id}/status`, { status });
    if (data.parent?.changed && data.parent.status === 'done') {
      toast.success(t('tasks.parentDone', { title: data.parent.title }));
    } else if (data.parent?.changed) {
      toast.push({ type: 'info', title: t('tasks.parentReopened', { title: data.parent.title }) });
    } else if (status === 'done') {
      toast.success(t('tasks.completed'), task.title);
    }
    // Parent status and subtask progress are computed on the server.
    if (data.parent) await load();
  } catch (e) {
    apply(prev);
    toast.error(t('tasks.statusFailed'), errMsg(e));
  }
}

function openNotes(task, plan) {
  notesPlanId.value = plan.id;
  notesTask.value = task;
}

function setNoteCount(task, count) {
  if (!task) return;
  weekPlans.value.forEach((p) => p.tasks.forEach((x) => x.id === task.id && (x.note_count = count)));
}

async function afterChange() {
  notifyPlansChanged();
  await load();
}

const planDone = (p) => p.tasks.filter((task) => task.status === 'done').length;
</script>

<template>
  <div class="plan-page">
    <section class="page-head">
      <div>
        <h1>{{ fmtDateLong(date) }}</h1>
        <div class="day-progress" :title="t('plan.dayPassed', { p: Math.round(dayProgress) })">
          <div :style="{ width: dayProgress + '%' }"></div>
        </div>
      </div>
      <div class="head-actions">
        <div class="btn-group">
          <button class="btn ghost" @click="date = addDays(date, -1)">‹</button>
          <button class="btn ghost" :class="{ active: isToday }" @click="date = todayStr">{{ t('plan.today') }}</button>
          <button class="btn ghost" @click="date = addDays(date, 1)">›</button>
        </div>
        <input v-model="date" type="date" class="date-input" />
        <button class="btn ghost" :disabled="!plans.length" @click="generateOpen = true">⟳ {{ t('plan.copyToWeek') }}</button>
        <button class="btn primary" @click="openCreate()">+ {{ t('plan.new') }}</button>
      </div>
    </section>

    <section class="week-strip">
      <button
        v-for="d in weekSummary"
        :key="d.date"
        class="week-day"
        :class="{ active: d.date === date, today: d.date === todayStr }"
        @click="date = d.date"
      >
        <div class="wd-top">
          <span>{{ weekdayShort(d.date) }}</span>
          <b>{{ parseDate(d.date).getDate() }}</b>
        </div>
        <div class="wd-bar">
          <span
            v-for="p in d.items"
            :key="p.id"
            :style="{ background: p.project_color, flex: p.end_min - p.start_min }"
          ></span>
          <span class="wd-free" :style="{ flex: Math.max(0, workDay - d.minutes) }"></span>
        </div>
        <small class="muted">{{ d.minutes ? fmtDuration(d.minutes) : t('plan.empty') }}</small>
      </button>
    </section>

    <section class="card timeline-card">
      <div class="card-head">
        <h3>{{ t('plan.schedule') }}</h3>
        <span class="muted small">{{ t('plan.clickToAdd') }}</span>
      </div>
      <DayTimeline
        :key="date"
        :plans="plans"
        :start-min="settings.work_start_min"
        :end-min="settings.work_end_min"
        :now-min="isToday ? nowMin : null"
        :now-sec="nowSec"
        :selected-id="selected?.id ?? null"
        :tracking="planTracking"
        :preview="pendingMove && { id: pendingMove.plan.id, start_min: pendingMove.start_min, end_min: pendingMove.end_min }"
        @select="selectedId = $event.id"
        @create="openCreate"
        @change="pendingMove = $event"
        @invalid="toast.error(t('drag.overlap'), t('drag.overlapDesc'))"
      />
    </section>

    <div class="plan-grid">
      <div class="plan-main">
        <Transition name="fade" mode="out-in">
          <section v-if="selected" :key="selected.id" class="card plan-detail" :style="{ '--c': selected.project_color }">
            <div class="card-head">
              <div>
                <h3><span class="dot" :style="{ background: selected.project_color }"></span> {{ selected.project_name }}</h3>
                <div class="muted small">
                  {{ fmtMin(selected.start_min) }} – {{ fmtMin(selected.end_min) }} ·
                  {{ fmtDuration(selected.end_min - selected.start_min) }}
                </div>
              </div>
              <div class="actions">
                <button class="icon-btn" :title="t('common.edit')" @click="openEdit(selected)">✎</button>
                <button class="icon-btn" :title="t('postpone.title')" @click="postponing = selected">⏭</button>
                <button class="icon-btn" :title="t('plan.syncTasks')" @click="syncTasks(selected)">⟳</button>
                <button class="icon-btn danger" :title="t('common.delete')" @click="deletePlan(selected)">🗑</button>
              </div>
            </div>
            <p v-if="selected.note" class="note">{{ selected.note }}</p>
            <TrackingPanel
              v-if="selected.plan_date <= todayStr"
              :plan="selected"
              :now-ms="nowMs"
              :loaded-at="loadedAt"
              :busy="trackingBusy"
              @start="startTracking(selected)"
              @pause="pauseTracking(selected)"
            />
            <div class="progress-line">
              <div :style="{ width: (selected.tasks.length ? (planDone(selected) / selected.tasks.length) * 100 : 0) + '%' }"></div>
            </div>
            <ul class="task-list">
              <TransitionGroup name="list">
                <li
                  v-for="{ task, sub, childCount } in selectedRows"
                  :key="task.id"
                  class="task-row"
                  :class="{ done: task.status === 'done', sub }"
                >
                  <button
                    v-if="!sub && hasSubtaskRows"
                    class="expand-btn"
                    :class="{ open: childCount && !collapsedTasks.has(task.id), 'no-subs': !childCount }"
                    :disabled="!childCount"
                    :title="collapsedTasks.has(task.id) ? t('tasks.expand') : t('tasks.collapse')"
                    @click="toggleTask(task)"
                  >
                    ▸
                  </button>
                  <input
                    type="checkbox"
                    :checked="task.status === 'done'"
                    @change="setTaskStatus(task, $event.target.checked ? 'done' : 'todo')"
                  />
                  <span class="task-title">
                    <small v-if="task.parent_title && !sub" class="parent-crumb">{{ task.parent_title }} ›</small>
                    {{ task.title }}
                  </span>
                  <span
                    v-if="task.subtask_count"
                    class="sub-progress"
                    :class="{ complete: task.subtask_done === task.subtask_count }"
                    :title="t('tasks.subtaskProgress', { done: task.subtask_done, total: task.subtask_count })"
                  >
                    <span class="sub-progress-bar">
                      <span :style="{ width: (task.subtask_done / task.subtask_count) * 100 + '%' }"></span>
                    </span>
                    {{ task.subtask_done }}/{{ task.subtask_count }}
                  </span>
                  <button
                    class="note-btn"
                    :class="{ has: task.note_count }"
                    :title="t('notes.open')"
                    @click="openNotes(task, selected)"
                  >
                    📝<span v-if="task.note_count">{{ task.note_count }}</span>
                  </button>
                  <TaskStatusSelect :model-value="task.status" @update:model-value="setTaskStatus(task, $event)" />
                </li>
              </TransitionGroup>
              <li v-if="!selected.tasks.length" class="muted">{{ t('plan.noTasks') }}</li>
            </ul>
          </section>
          <section v-else-if="!loading" class="card plan-empty muted">{{ t('plan.noPlansDay') }}</section>
        </Transition>
      </div>

      <aside class="side">
        <section v-if="isToday" class="card now-card" :class="{ warning: countdown?.warning }">
          <template v-if="countdown">
            <CountdownRing
              :total-sec="countdown.total"
              :remaining-sec="countdown.remaining"
              :color="countdown.color"
              :warning="countdown.warning"
              :caption="countdown.caption"
            />
            <div class="now-info">
              <div class="muted small">{{ currentPlan ? t('plan.now') : t('plan.next') }}</div>
              <h2>
                <span class="dot lg" :style="{ background: (currentPlan ?? nextPlan).project_color }"></span>
                {{ (currentPlan ?? nextPlan).project_name }}
              </h2>
              <div class="muted">
                {{ fmtMin((currentPlan ?? nextPlan).start_min) }} – {{ fmtMin((currentPlan ?? nextPlan).end_min) }}
              </div>
              <div v-if="currentPlan && nextPlan" class="next-up">
                {{ t('plan.then') }}: <span class="dot" :style="{ background: nextPlan.project_color }"></span>
                {{ nextPlan.project_name }} · {{ fmtMin(nextPlan.start_min) }}
              </div>
              <div v-if="countdown.warning" class="warn-text">⏰ {{ t('plan.almostOver') }}</div>
              <TrackingPanel
                v-if="currentPlan"
                compact
                :plan="currentPlan"
                :now-ms="nowMs"
                :loaded-at="loadedAt"
                :busy="trackingBusy"
                @start="startTracking(currentPlan)"
                @pause="pauseTracking(currentPlan)"
              />
            </div>
          </template>
          <div v-else class="empty-now">
            <div class="big-emoji">☕</div>
            <div>{{ t('plan.noActive') }}</div>
          </div>
        </section>

        <section class="stats">
          <div class="stat card">
            <span class="muted small">{{ t('plan.planned') }}</span>
            <b>{{ fmtDuration(plannedMin) }}</b>
            <div class="mini-bar"><div :style="{ width: (plannedMin / workDay) * 100 + '%' }"></div></div>
          </div>
          <div class="stat card">
            <span class="muted small">{{ t('plan.freeTime') }}</span>
            <b>{{ fmtDuration(Math.max(0, workDay - plannedMin)) }}</b>
            <div class="mini-bar free"><div :style="{ width: ((workDay - plannedMin) / workDay) * 100 + '%' }"></div></div>
          </div>
          <div class="stat card">
            <span class="muted small">{{ t('plan.tasks') }}</span>
            <b>{{ doneTasks }}/{{ dayTasks.length }}</b>
            <div class="mini-bar ok">
              <div :style="{ width: (dayTasks.length ? (doneTasks / dayTasks.length) * 100 : 0) + '%' }"></div>
            </div>
          </div>
          <div class="stat card">
            <span class="muted small">{{ t('tracking.effective') }}</span>
            <b>{{ fmtSeconds(dayEffective) }}</b>
            <div class="mini-bar ok"><div :style="{ width: Math.min(100, (dayEffective / 60 / Math.max(1, plannedMin)) * 100) + '%' }"></div></div>
          </div>
          <div class="stat card">
            <span class="muted small">{{ t('tracking.breaks') }}</span>
            <b>{{ fmtSeconds(dayBreaks) }}</b>
            <div class="mini-bar free"><div :style="{ width: Math.min(100, (dayBreaks / 60 / Math.max(1, plannedMin)) * 100) + '%' }"></div></div>
          </div>
          <div class="stat card" :title="t('tracking.efficiencyHint')">
            <span class="muted small">{{ t('tracking.efficiency') }}</span>
            <b :class="['eff-text', dayEffLevel]">{{ dayEfficiency === null ? '—' : dayEfficiency + '%' }}</b>
            <div class="eff-bar sm">
              <div class="eff-fill" :class="dayEffLevel" :style="{ width: Math.min(dayEfficiency ?? 0, 100) + '%' }"></div>
              <div class="eff-target" :style="{ left: settings.target_efficiency_pct + '%' }"></div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card-head"><h3>{{ t('plan.distribution') }}</h3></div>
          <DonutChart
            :segments="segments"
            :center-title="fmtDuration(plannedMin)"
            :center-sub="t('plan.filled', { p: Math.round((plannedMin / workDay) * 100) })"
          />
        </section>

      </aside>
    </div>

    <PlanFormModal
      :show="formOpen"
      :plan="editing"
      :projects="projects"
      :defaults="formDefaults"
      :work-start="settings.work_start_min"
      :work-end="settings.work_end_min"
      :saving="saving"
      @close="formOpen = false"
      @save="savePlan"
    />
    <ShiftChoiceModal
      :show="!!shiftState"
      :delta="shiftState?.delta"
      :following="shiftState?.following"
      @close="shiftState = null"
      @choose="updatePlan(shiftState.plan.id, shiftState.form, $event)"
    />
    <AppModal :show="!!pendingMove" :title="t('drag.title')" @close="pendingMove = null">
      <template v-if="pendingMove">
        <h3 class="move-plan-name">
          <span class="dot" :style="{ background: pendingMove.plan.project_color }"></span>
          {{ pendingMove.plan.project_name }}
        </h3>
        <div class="drag-diff">
          <span class="muted">{{ t('drag.before') }}</span>
          <span class="old">
            {{ fmtMin(pendingMove.plan.start_min) }} – {{ fmtMin(pendingMove.plan.end_min) }}
            · {{ fmtDuration(pendingMove.plan.end_min - pendingMove.plan.start_min) }}
          </span>
          <span class="muted">{{ t('drag.after') }}</span>
          <b>
            {{ fmtMin(pendingMove.start_min) }} – {{ fmtMin(pendingMove.end_min) }}
            · {{ fmtDuration(pendingMove.end_min - pendingMove.start_min) }}
          </b>
        </div>
      </template>
      <template #footer>
        <button class="btn ghost" :disabled="saving" @click="pendingMove = null">{{ t('common.cancel') }}</button>
        <button class="btn primary" :disabled="saving" @click="confirmMove">{{ t('drag.confirm') }}</button>
      </template>
    </AppModal>
    <PostponeModal
      :show="!!postponing"
      :plan="postponing"
      :work-start="settings.work_start_min"
      :work-end="settings.work_end_min"
      :saving="saving"
      @close="postponing = null"
      @save="postpone"
    />
    <TaskNotesModal
      :task="notesTask"
      :plan-id="notesPlanId"
      @close="notesTask = null"
      @count="setNoteCount(notesTask, $event)"
    />
    <GenerateModal
      :show="generateOpen"
      :source-date="date"
      :plan-count="plans.length"
      :saving="saving"
      @close="generateOpen = false"
      @generate="generate"
    />
  </div>
</template>
