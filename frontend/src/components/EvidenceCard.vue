<template>
  <div class="bg-white rounded-xl shadow-sm overflow-hidden flex flex-col">
    <!-- Preview -->
    <div class="h-40 bg-gray-100 flex items-center justify-center overflow-hidden">
      <img
        v-if="item.mime_type.startsWith('image/')"
        :src="`/api/uploads/${item.filename}`"
        :alt="item.original_name"
        class="w-full h-full object-cover"
      />
      <video
        v-else-if="item.mime_type.startsWith('video/')"
        :src="`/api/uploads/${item.filename}`"
        class="w-full h-full object-cover"
      />
      <div v-else class="text-5xl">{{ fileIcon(item.mime_type) }}</div>
    </div>

    <!-- Info -->
    <div class="p-4 flex flex-col gap-1 flex-1">
      <p class="text-sm font-medium text-gray-900 truncate" :title="item.original_name">
        {{ item.original_name }}
      </p>
      <p v-if="item.description" class="text-xs text-gray-500 line-clamp-2">
        {{ item.description }}
      </p>
      <div class="flex items-center gap-2 mt-1 flex-wrap">
        <span class="text-xs text-gray-400">{{ formatDate(item.created_at) }}</span>
        <span
          v-if="item.latitude !== null && item.longitude !== null"
          class="inline-flex items-center gap-1 text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full"
        >
          📍 Location
        </span>
      </div>
    </div>

    <!-- Delete -->
    <div class="px-4 pb-4">
      <button
        class="w-full text-xs text-red-500 hover:text-red-700 border border-red-200 hover:border-red-400 rounded-lg py-1.5 transition-colors"
        @click="$emit('delete', item.id)"
      >
        Delete
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Evidence } from '../types'

defineProps<{ item: Evidence }>()
defineEmits<{ delete: [id: string] }>()

function fileIcon(mime: string): string {
  if (mime.startsWith('audio/')) return '🎵'
  if (mime.includes('pdf')) return '📄'
  if (mime.includes('word') || mime.includes('document')) return '📝'
  return '📁'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}
</script>
