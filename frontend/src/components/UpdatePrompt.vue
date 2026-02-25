<template>
  <div
    v-if="needRefresh"
    class="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-lg text-sm"
  >
    <span>A new version is available.</span>
    <button
      @click="updateServiceWorker()"
      class="bg-indigo-500 hover:bg-indigo-400 text-white px-3 py-1 rounded-lg font-medium transition-colors"
    >
      Update
    </button>
    <button
      @click="close()"
      class="text-gray-400 hover:text-white transition-colors ml-1"
      aria-label="Dismiss"
    >
      ✕
    </button>
  </div>
</template>

<script setup lang="ts">
import { useRegisterSW } from 'virtual:pwa-register/vue'

const { needRefresh, updateServiceWorker } = useRegisterSW()

function close() {
  needRefresh.value = false
}
</script>
