<template>
  <div class="flex gap-3 px-5 py-3.5 border-t border-gray-200 bg-white">
    <input
      v-model="text"
      type="text"
      placeholder="Type a message…"
      class="flex-1 px-3.5 py-2.5 border border-gray-200 rounded-3xl text-sm outline-none focus:border-indigo-500 transition-colors"
      @keydown.enter="handleSend"
    />
    <button
      @click="handleSend"
      :disabled="!text.trim()"
      class="px-5 py-2.5 bg-indigo-600 text-white border-none rounded-3xl text-sm font-semibold hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
    >
      Send
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const emit = defineEmits<{ send: [content: string] }>()
const text = ref('')

function handleSend() {
  const content = text.value.trim()
  if (!content) return
  emit('send', content)
  text.value = ''
}
</script>
