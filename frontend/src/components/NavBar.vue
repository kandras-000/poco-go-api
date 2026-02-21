<template>
  <nav class="navbar">
    <span class="brand">Poco Chat</span>
    <div class="nav-right">
      <span class="username">{{ auth.user?.username ?? '...' }}</span>
      <button class="btn-logout" @click="handleLogout">Sign out</button>
    </div>
  </nav>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useChatStore } from '../stores/chat'

const auth = useAuthStore()
const chat = useChatStore()
const router = useRouter()

function handleLogout() {
  chat.disconnectWebSocket()
  auth.logout()
  router.push('/login')
}
</script>

<style scoped>
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1.5rem;
  height: 56px;
  background: #4f46e5;
  color: #fff;
  flex-shrink: 0;
}

.brand {
  font-size: 1.2rem;
  font-weight: 700;
  letter-spacing: 0.5px;
}

.nav-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.username {
  font-size: 0.9rem;
  opacity: 0.9;
}

.btn-logout {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: #fff;
  padding: 0.35rem 0.85rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: background 0.15s;
}

.btn-logout:hover {
  background: rgba(255, 255, 255, 0.35);
}
</style>
