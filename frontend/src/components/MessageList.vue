<template>
  <div class="message-list" ref="listEl">
    <div
      v-for="msg in messages"
      :key="msg.id"
      class="message"
      :class="msg.sender_id === currentUserId ? 'sent' : 'received'"
    >
      <div class="sender-label">{{ msg.sender_username }}</div>
      <div class="bubble">{{ msg.content }}</div>
      <div class="meta">{{ formatTime(msg.created_at) }}</div>
    </div>
    <div v-if="messages.length === 0" class="empty">No messages yet. Say hello!</div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import type { Message } from '../types'

const props = defineProps<{
  messages: Message[]
  currentUserId: string
}>()

const listEl = ref<HTMLElement | null>(null)

function formatTime(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

watch(
  () => props.messages.length,
  async () => {
    await nextTick()
    if (listEl.value) {
      listEl.value.scrollTop = listEl.value.scrollHeight
    }
  },
)
</script>

<style scoped>
.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.message {
  display: flex;
  flex-direction: column;
  max-width: 65%;
}

.message.sent {
  align-self: flex-end;
  align-items: flex-end;
}

.message.received {
  align-self: flex-start;
  align-items: flex-start;
}

.bubble {
  padding: 0.55rem 0.9rem;
  border-radius: 18px;
  font-size: 0.95rem;
  line-height: 1.45;
  word-break: break-word;
}

.sent .bubble {
  background: #4f46e5;
  color: #fff;
  border-bottom-right-radius: 4px;
}

.received .bubble {
  background: #f3f4f6;
  color: #111827;
  border-bottom-left-radius: 4px;
}

.sender-label {
  font-size: 0.72rem;
  font-weight: 600;
  color: #6b7280;
  margin-bottom: 0.2rem;
  padding: 0 0.2rem;
}

.meta {
  font-size: 0.72rem;
  color: #9ca3af;
  margin-top: 0.2rem;
  padding: 0 0.2rem;
}

.empty {
  margin: auto;
  color: #9ca3af;
  font-size: 0.9rem;
}
</style>
