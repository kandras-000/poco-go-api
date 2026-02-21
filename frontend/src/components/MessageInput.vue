<template>
  <div class="message-input">
    <input
      v-model="text"
      type="text"
      placeholder="Type a message…"
      @keydown.enter="handleSend"
    />
    <button @click="handleSend" :disabled="!text.trim()" class="btn-send">Send</button>
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

<style scoped>
.message-input {
  display: flex;
  gap: 0.75rem;
  padding: 0.85rem 1.25rem;
  border-top: 1px solid #e5e7eb;
  background: #fff;
}

input {
  flex: 1;
  padding: 0.6rem 0.9rem;
  border: 1px solid #e5e7eb;
  border-radius: 24px;
  font-size: 0.95rem;
  outline: none;
  transition: border-color 0.15s;
}

input:focus {
  border-color: #4f46e5;
}

.btn-send {
  padding: 0.6rem 1.2rem;
  background: #4f46e5;
  color: #fff;
  border: none;
  border-radius: 24px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: background 0.15s;
  font-weight: 600;
}

.btn-send:hover:not(:disabled) {
  background: #4338ca;
}

.btn-send:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
