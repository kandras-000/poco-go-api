import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import LoginView from '../views/LoginView.vue'
import RegisterView from '../views/RegisterView.vue'
import ChatView from '../views/ChatView.vue'
import EvidenceView from '../views/EvidenceView.vue'
import ContainerView from '../views/ContainerView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/chat' },
    { path: '/login',           name: 'login',      component: LoginView },
    { path: '/register',        name: 'register',   component: RegisterView },
    { path: '/chat',            name: 'chat',       component: ChatView,      meta: { requiresAuth: true } },
    { path: '/evidence',        name: 'evidence',   component: EvidenceView,  meta: { requiresAuth: true } },
    { path: '/evidence/:id',    name: 'container',  component: ContainerView, meta: { requiresAuth: true } },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isAuthenticated) return { name: 'login' }
  if ((to.name === 'login' || to.name === 'register') && auth.isAuthenticated) return { name: 'chat' }
})

export default router
