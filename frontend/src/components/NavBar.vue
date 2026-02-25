<template>
  <nav class="flex items-center justify-between px-6 h-14 bg-indigo-600 text-white shrink-0">
    <span class="text-xl font-bold tracking-wide">Poco Chat</span>

    <!-- Desktop nav -->
    <div class="hidden sm:flex items-center gap-6">
      <RouterLink
        to="/chat"
        class="text-sm text-white/80 hover:text-white transition-colors"
        active-class="text-white font-semibold"
      >
        Chat
      </RouterLink>
      <RouterLink
        to="/evidence"
        class="text-sm text-white/80 hover:text-white transition-colors"
        active-class="text-white font-semibold"
      >
        Evidence
      </RouterLink>
    </div>

    <div class="flex items-center gap-3">
      <span class="hidden sm:inline text-sm opacity-90">{{ auth.user?.username ?? '...' }}</span>
      <button
        class="bg-white/20 hover:bg-white/35 transition-colors text-white px-3.5 py-1.5 rounded-md text-sm font-medium"
        @click="handleLogout"
      >
        Sign out
      </button>
      <!-- Mobile hamburger -->
      <button
        class="sm:hidden flex flex-col gap-1 p-1"
        @click="mobileOpen = !mobileOpen"
        aria-label="Menu"
      >
        <span class="block w-5 h-0.5 bg-white"></span>
        <span class="block w-5 h-0.5 bg-white"></span>
        <span class="block w-5 h-0.5 bg-white"></span>
      </button>
    </div>
  </nav>

  <!-- Mobile dropdown -->
  <div v-if="mobileOpen" class="sm:hidden bg-indigo-700 text-white px-6 py-3 flex flex-col gap-3">
    <RouterLink
      to="/chat"
      class="text-sm"
      @click="mobileOpen = false"
    >
      Chat
    </RouterLink>
    <RouterLink
      to="/evidence"
      class="text-sm"
      @click="mobileOpen = false"
    >
      Evidence
    </RouterLink>
    <span class="text-sm opacity-80">{{ auth.user?.username }}</span>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { useChatStore } from '../stores/chat'

const auth = useAuthStore()
const chat = useChatStore()
const router = useRouter()
const mobileOpen = ref(false)

function handleLogout() {
  chat.disconnectWebSocket()
  auth.logout()
  router.push('/login')
}
</script>
