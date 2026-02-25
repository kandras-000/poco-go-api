<template>
  <div class="flex-1 overflow-y-auto p-5 flex flex-col gap-2" ref="listEl">
    <div
      v-for="msg in messages"
      :key="msg.id"
      class="flex flex-col max-w-[65%]"
      :class="msg.sender_id === currentUserId ? 'self-end items-end' : 'self-start items-start'"
    >
      <div class="text-xs font-semibold text-gray-500 mb-0.5 px-0.5">
        {{ msg.sender_username }}
      </div>
      <div
        class="px-3.5 py-2 rounded-[18px] text-sm leading-relaxed break-words"
        :class="
          msg.sender_id === currentUserId
            ? 'bg-indigo-600 text-white rounded-br-sm'
            : 'bg-gray-100 text-gray-900 rounded-bl-sm'
        "
      >
        {{ msg.content }}
      </div>
      <div class="text-xs text-gray-400 mt-0.5 px-0.5">{{ formatTime(msg.created_at) }}</div>
    </div>
    <div v-if="messages.length === 0" class="m-auto text-gray-400 text-sm">
      No messages yet. Say hello!
    </div>
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
