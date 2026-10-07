<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import api, { errMsg, notifyPlansChanged } from '../api';
import { useSettingsStore } from '../stores/settings';
import { useToast } from '../stores/toast';
import { useNow } from '../composables/useNow';
import { t } from '../i18n';
import {
  addDays, fmtDateLong, fmtDuration, fmtMin, parseDate, toDateStr, weekDates, weekdayShort,
} from '../utils/time';
import DayTimeline from '../components/DayTimeline.vue';
import DonutChart from '../components/DonutChart.vue';
import CountdownRing from '../components/CountdownRing.vue';
import TaskStatusSelect from '../components/TaskStatusSelect.vue';
import PlanFormModal from '../components/PlanFormModal.vue';
import ShiftChoiceModal from '../components/ShiftChoiceModal.vue';
import PostponeModal from '../components/PostponeModal.vue';
import GenerateModal from '../components/GenerateModal.vue';

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

const formOpen = ref(false);
const editing = ref(null);
const formDefaults = ref({});
const shiftState = ref(null); // { plan, form, delta, following }
const postponing = ref(null);
const generateOpen = ref(false);

const week = computed(() => weekDates(date.value));
const plans = computed(() => weekPlans.value.filter((p) => p.plan_date === date.value));

const todayStr = computed(() => toDateStr(now.value));
const isToday = computed(() => date.value === todayStr.value);
const nowMin = computed(() => now.value.getHours() * 60 + now.value.getMinutes());
const nowSec = computed(() => nowMin.value * 60 + now.value.getSeconds());

const currentPlan = computed(() =>
  isToday.value ? plans.value.find((p) => p.start_min <= nowMin.value && nowMin.value < p.end_min) ?? null : null,
);
const nextPlan = computed(() => (isToday.value ? plans.value.find((p) => p.start_min > nowMin.value) ?? null : null));
const selected = computed(
  () => plans.value.find((p) => p.id === selectedId.value) ?? currentPlan.value ?? plans.value[0] ?? null,
);

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
onMounted(load);

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
    await api.patch(`/tasks/${task.id}/status`, { status });
    if (status === 'done') toast.success(t('tasks.completed'), task.title);
  } catch (e) {
    apply(prev);
    toast.error(t('tasks.statusFailed'), errMsg(e));
  }
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

    <div class="plan-grid">
      <section class="card timeline-card">
        <div class="card-head">
          <h3>{{ t('plan.schedule') }}</h3>
          <span class="muted small">{{ t('plan.clickToAdd') }}</span>
        </div>
        <DayTimeline
          :plans="plans"
          :start-min="settings.work_start_min"
          :end-min="settings.work_end_min"
          :now-min="isToday ? nowMin : null"
          :now-sec="nowSec"
          :selected-id="selected?.id ?? null"
          @select="selectedId = $event.id"
          @create="openCreate"
        />
      </section>

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
        </section>

        <section class="card">
          <div class="card-head"><h3>{{ t('plan.distribution') }}</h3></div>
          <DonutChart
            :segments="segments"
            :center-title="fmtDuration(plannedMin)"
            :center-sub="t('plan.filled', { p: Math.round((plannedMin / workDay) * 100) })"
          />
        </section>

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
            <div class="progress-line">
              <div :style="{ width: (selected.tasks.length ? (planDone(selected) / selected.tasks.length) * 100 : 0) + '%' }"></div>
            </div>
            <ul class="task-list">
              <TransitionGroup name="list">
                <li v-for="task in selected.tasks" :key="task.id" :class="{ done: task.status === 'done' }">
                  <input
                    type="checkbox"
                    :checked="task.status === 'done'"
                    @change="setTaskStatus(task, $event.target.checked ? 'done' : 'todo')"
                  />
                  <span class="task-title">{{ task.title }}</span>
                  <TaskStatusSelect :model-value="task.status" @update:model-value="setTaskStatus(task, $event)" />
                </li>
              </TransitionGroup>
              <li v-if="!selected.tasks.length" class="muted">{{ t('plan.noTasks') }}</li>
            </ul>
          </section>
        </Transition>
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
    <PostponeModal
      :show="!!postponing"
      :plan="postponing"
      :work-start="settings.work_start_min"
      :work-end="settings.work_end_min"
      :saving="saving"
      @close="postponing = null"
      @save="postpone"
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
