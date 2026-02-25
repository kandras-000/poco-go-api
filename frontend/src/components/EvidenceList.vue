<template>
  <div>
    <h2 class="text-lg font-semibold text-gray-900 mb-4">Your Evidence</h2>

    <div v-if="evidenceStore.loading" class="flex justify-center py-12">
      <span class="animate-spin w-8 h-8 border-2 border-gray-200 border-t-indigo-600 rounded-full" />
    </div>

    <p v-else-if="evidenceStore.error" class="text-red-500 text-sm">{{ evidenceStore.error }}</p>

    <div
      v-else-if="evidenceStore.items.length > 0"
      class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      <div
        v-for="item in evidenceStore.items"
        :key="item.id"
        class="bg-white rounded-xl shadow-sm overflow-hidden flex flex-col"
      >
        <!-- Preview area -->
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
            @click="handleDelete(item.id)"
          >
            Delete
          </button>
        </div>
      </div>
    </div>

    <div v-else class="text-center py-16">
      <div class="text-5xl mb-4">📂</div>
      <p class="text-gray-400 text-base">No evidence uploaded yet.</p>
      <p class="text-gray-400 text-sm mt-1">Use the form above to add your first item.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useEvidenceStore } from '../stores/evidence'

const evidenceStore = useEvidenceStore()

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

async function handleDelete(id: string) {
  if (!confirm('Delete this evidence item? This cannot be undone.')) return
  try {
    await evidenceStore.deleteEvidence(id)
  } catch {
    alert('Failed to delete evidence.')
  }
}
</script>
