<template>
  <aside class="w-64 shrink-0 bg-white border-r border-gray-200 flex flex-col">
    <div class="px-5 py-4 border-b border-gray-200">
      <h3 class="text-xs uppercase tracking-wider text-gray-500 font-semibold">Users</h3>
    </div>
    <div class="overflow-y-auto flex-1 py-2">
      <button
        v-for="user in filteredUsers"
        :key="user.id"
        class="flex items-center gap-3 w-full px-5 py-2.5 text-left cursor-pointer hover:bg-gray-50 transition-colors"
        :class="{ 'bg-indigo-50': selectedUser?.id === user.id }"
        @click="$emit('select', user)"
      >
        <div class="w-9 h-9 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-base shrink-0">
          {{ user.username[0].toUpperCase() }}
        </div>
        <span class="text-sm font-medium text-gray-900">{{ user.username }}</span>
      </button>
      <p v-if="filteredUsers.length === 0" class="px-5 py-4 text-gray-400 text-sm">
        No other users yet.
      </p>
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
