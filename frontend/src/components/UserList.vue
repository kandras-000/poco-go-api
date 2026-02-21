<template>
  <aside class="user-list">
    <div class="header">
      <h3>Users</h3>
    </div>
    <div class="list">
      <button
        v-for="user in filteredUsers"
        :key="user.id"
        class="user-item"
        :class="{ active: selectedUser?.id === user.id }"
        @click="$emit('select', user)"
      >
        <div class="avatar">{{ user.username[0].toUpperCase() }}</div>
        <div class="info">
          <span class="name">{{ user.username }}</span>
        </div>
      </button>
      <p v-if="filteredUsers.length === 0" class="empty">No other users yet.</p>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { User } from '../types'

const props = defineProps<{
  users: User[]
  selectedUser: User | null
  currentUserId?: string
}>()

defineEmits<{ select: [user: User] }>()

const filteredUsers = computed(() =>
  props.users.filter((u) => u.id !== props.currentUserId),
)
</script>

<style scoped>
.user-list {
  width: 260px;
  flex-shrink: 0;
  background: #fff;
  border-right: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
}

.header {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #e5e7eb;
}

.header h3 {
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: #6b7280;
  font-weight: 600;
}

.list {
  overflow-y: auto;
  flex: 1;
  padding: 0.5rem 0;
}

.user-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.65rem 1.25rem;
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  transition: background 0.12s;
  border-radius: 0;
}

.user-item:hover {
  background: #f9fafb;
}

.user-item.active {
  background: #eef2ff;
}

.avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #4f46e5;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1rem;
  flex-shrink: 0;
}

.name {
  font-size: 0.95rem;
  font-weight: 500;
  color: #111827;
}

.empty {
  padding: 1rem 1.25rem;
  color: #9ca3af;
  font-size: 0.875rem;
}
</style>
