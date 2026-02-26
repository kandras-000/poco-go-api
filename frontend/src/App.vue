<template>
  <div id="app" class="h-screen flex flex-col bg-gray-100 text-gray-900">
    <NavBar v-if="auth.isAuthenticated" />
    <RouterView />
    <UpdatePrompt />
    <InstallPrompt />
  </div>
</template>

<script setup lang="ts">
import { RouterView } from 'vue-router'
import NavBar from './components/NavBar.vue'
import UpdatePrompt from './components/UpdatePrompt.vue'
import InstallPrompt from './components/InstallPrompt.vue'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()
</script>
