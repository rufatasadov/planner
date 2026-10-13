import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from './stores/auth';

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: () => import('./views/LoginView.vue'), meta: { public: true } },
    { path: '/', component: () => import('./views/PlanView.vue') },
    { path: '/projects', component: () => import('./views/ProjectsView.vue') },
    { path: '/projects/:id', component: () => import('./views/ProjectDetailView.vue'), props: true },
    { path: '/notes', component: () => import('./views/NotesView.vue') },
    { path: '/settings', component: () => import('./views/SettingsView.vue') },
    { path: '/admin', component: () => import('./views/AdminView.vue'), meta: { admin: true } },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
});

router.beforeEach(async (to) => {
  const auth = useAuthStore();
  if (!to.meta.public && !auth.token) return '/login';
  if (to.path === '/login' && auth.token) return '/';
  if (to.meta.admin) {
    // Sessions saved before the admin flag existed have no is_admin yet.
    if (auth.user?.is_admin === undefined) await auth.fetchMe().catch(() => {});
    if (!auth.user?.is_admin) return '/';
  }
});

export default router;
