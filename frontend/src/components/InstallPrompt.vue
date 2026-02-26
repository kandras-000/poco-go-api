<template>
  <!-- Android / desktop: native install prompt available -->
  <div
    v-if="showInstall"
    class="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-lg text-sm w-max max-w-[calc(100vw-2rem)]"
  >
    <span>Install Case Builder as an app.</span>
    <button
      @click="install"
      class="bg-indigo-500 hover:bg-indigo-400 text-white px-3 py-1 rounded-lg font-medium transition-colors shrink-0"
    >
      Install
    </button>
    <button
      @click="dismiss"
      class="text-gray-400 hover:text-white transition-colors ml-1 shrink-0"
      aria-label="Dismiss"
    >
      ✕
    </button>
  </div>

  <!-- iOS: no programmatic prompt, show manual instructions -->
  <div
    v-else-if="showIos"
    class="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 flex items-center gap-3 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-lg text-sm w-max max-w-[calc(100vw-2rem)]"
  >
    <span>Tap <strong>Share</strong> then <strong>Add to Home Screen</strong> to install.</span>
    <button
      @click="dismissIos"
      class="text-gray-400 hover:text-white transition-colors ml-1 shrink-0"
      aria-label="Dismiss"
    >
      ✕
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'

const showInstall = ref(false)
const showIos = ref(false)

let deferredPrompt: BeforeInstallPromptEvent | null = null

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

const isStandalone =
  window.matchMedia('(display-mode: standalone)').matches ||
  ('standalone' in window.navigator && (window.navigator as { standalone?: boolean }).standalone === true)

function handleBeforeInstallPrompt(e: Event) {
  e.preventDefault()
  deferredPrompt = e as BeforeInstallPromptEvent
  if (!sessionStorage.getItem('pwa-install-dismissed')) {
    showInstall.value = true
  }
}

async function install() {
  if (!deferredPrompt) return
  showInstall.value = false
  await deferredPrompt.prompt()
  await deferredPrompt.userChoice
  deferredPrompt = null
}

function dismiss() {
  showInstall.value = false
  sessionStorage.setItem('pwa-install-dismissed', '1')
}

function dismissIos() {
  showIos.value = false
  sessionStorage.setItem('pwa-install-dismissed', '1')
}

onMounted(() => {
  if (isStandalone) return

  const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent)
  if (isIos) {
    if (!sessionStorage.getItem('pwa-install-dismissed')) {
      showIos.value = true
    }
    return
  }

  window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
})

onUnmounted(() => {
  window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
})
</script>
