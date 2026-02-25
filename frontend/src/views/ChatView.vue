<template>
  <div class="flex-1 flex overflow-hidden">
    <UserList
      :users="chat.users"
      :selectedUser="chat.selectedUser"
      :currentUserId="auth.user?.id"
      @select="handleSelectUser"
    />

    <div class="flex-1 flex flex-col overflow-hidden">
      <template v-if="chat.selectedUser">
        <div class="flex items-center gap-3 px-5 py-3.5 bg-white border-b border-gray-200">
          <div class="w-9 h-9 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-sm shrink-0">
            {{ chat.selectedUser.username[0].toUpperCase() }}
          </div>
          <span class="font-semibold text-gray-900">{{ chat.selectedUser.username }}</span>
        </div>
        <MessageList
          :messages="currentMessages"
          :currentUserId="auth.user?.id ?? ''"
        />
        <MessageInput @send="handleSend" />
      </template>

      <div v-else class="flex-1 flex items-center justify-center">
        <p class="text-gray-400 text-base">Select a user from the left to start chatting.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'

import type { User } from '../types'
import { useAuthStore } from '../stores/auth'
import { useChatStore } from '../stores/chat'
import UserList from '../components/UserList.vue'
import MessageList from '../components/MessageList.vue'
import MessageInput from '../components/MessageInput.vue'

const auth = useAuthStore()
const chat = useChatStore()

const currentMessages = computed(() =>
  chat.selectedUser ? (chat.messages[chat.selectedUser.id] ?? []) : [],
)

async function handleSelectUser(user: User) {
  chat.selectUser(user)
  await chat.fetchMessages(user.id)
}

async function handleSend(content: string) {
  await chat.sendMessage(content)
}

onMounted(async () => {
  await chat.fetchUsers()
  if (auth.token) {
    chat.connectWebSocket(auth.token)
  }
})

onUnmounted(() => {
  chat.disconnectWebSocket()
})
</script>
