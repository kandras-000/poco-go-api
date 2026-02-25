<template>
  <div class="flex-1 overflow-y-auto bg-gray-100">
    <div class="max-w-4xl mx-auto px-4 py-8">

      <!-- Back + header -->
      <div class="flex items-center gap-3 mb-6">
        <button
          class="text-indigo-600 hover:text-indigo-800 text-sm font-medium flex items-center gap-1 transition-colors"
          @click="router.push('/evidence')"
        >
          ← Back
        </button>
        <span class="text-gray-300">|</span>
        <h1 class="text-xl font-bold text-gray-900 truncate">
          {{ container?.name ?? '…' }}
        </h1>
        <span v-if="container" class="text-xs text-gray-400 hidden sm:inline">
          {{ formatDate(container.created_at) }}
        </span>
      </div>

      <!-- Upload -->
      <EvidenceUpload :containerId="containerId" @uploaded="evidenceStore.fetchByContainer(containerId)" />

      <!-- Evidence list -->
      <div class="mt-8">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Evidence in this container</h2>

        <div v-if="evidenceStore.loading" class="flex justify-center py-12">
          <span class="animate-spin w-8 h-8 border-2 border-gray-200 border-t-indigo-600 rounded-full" />
        </div>

        <p v-else-if="evidenceStore.error" class="text-red-500 text-sm">{{ evidenceStore.error }}</p>

        <div
          v-else-if="evidenceStore.items.length > 0"
          class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4"
        >
          <EvidenceCard
            v-for="item in evidenceStore.items"
            :key="item.id"
            :item="item"
            @delete="handleDeleteEvidence"
          />
        </div>

        <div v-else class="text-center py-16">
          <div class="text-5xl mb-4">📂</div>
          <p class="text-gray-400 text-base">No evidence yet.</p>
          <p class="text-gray-400 text-sm mt-1">Use the form above to upload your first item.</p>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useContainerStore } from '../stores/containers'
import { useEvidenceStore } from '../stores/evidence'
import EvidenceUpload from '../components/EvidenceUpload.vue'
import EvidenceCard from '../components/EvidenceCard.vue'

const route = useRoute()
const router = useRouter()
const containerStore = useContainerStore()
const evidenceStore = useEvidenceStore()

const containerId = route.params.id as string

const container = computed(() =>
  containerStore.items.find((c) => c.id === containerId) ?? null,
)

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

async function handleDeleteEvidence(id: string) {
  if (!confirm('Delete this evidence item? This cannot be undone.')) return
  try {
    await evidenceStore.deleteEvidence(id)
  } catch {
    alert('Failed to delete evidence.')
  }
}

onMounted(async () => {
  if (containerStore.items.length === 0) {
    await containerStore.fetchContainers()
  }
  await evidenceStore.fetchByContainer(containerId)
})

onUnmounted(() => {
  evidenceStore.clear()
})
</script>
