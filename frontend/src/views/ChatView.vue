<template>
  <div class="chat-view">
    <UserList
      :users="chat.users"
      :selectedUser="chat.selectedUser"
      :currentUserId="auth.user?.id"
      @select="handleSelectUser"
    />

    <div class="chat-main">
      <template v-if="chat.selectedUser">
        <div class="chat-header">
          <div class="avatar">{{ chat.selectedUser.username[0].toUpperCase() }}</div>
          <span class="chat-with">{{ chat.selectedUser.username }}</span>
        </div>
        <MessageList
          :messages="currentMessages"
          :currentUserId="auth.user?.id ?? ''"
        />
        <MessageInput @send="handleSend" />
      </template>

      <div v-else class="no-selection">
        <div class="hint">
          <p>Select a user from the left to start chatting.</p>
        </div>
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

<style scoped>
.chat-view {
  flex: 1;
  display: flex;
  overflow: hidden;
}

.chat-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.chat-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.85rem 1.25rem;
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
}

.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #4f46e5;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.95rem;
  flex-shrink: 0;
}

.chat-with {
  font-weight: 600;
  font-size: 1rem;
  color: #111827;
}

.no-selection {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hint p {
  color: #9ca3af;
  font-size: 1rem;
}
</style>
