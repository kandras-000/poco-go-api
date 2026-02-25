<template>
  <div class="flex-1 overflow-y-auto bg-gray-100">
    <div class="max-w-4xl mx-auto px-4 py-8">

      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-gray-900">Evidence</h1>
        <button
          class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
          @click="showCreate = true"
        >
          + New Container
        </button>
      </div>

      <!-- New container form (inline) -->
      <div v-if="showCreate" class="bg-white rounded-xl shadow-sm p-5 mb-6">
        <h2 class="text-base font-semibold text-gray-900 mb-3">New Evidence Container</h2>
        <div class="flex gap-3">
          <input
            v-model="newName"
            type="text"
            placeholder="Container name…"
            maxlength="255"
            class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm outline-none focus:border-indigo-500 transition-colors"
            @keydown.enter="handleCreate"
            ref="nameInput"
          />
          <button
            :disabled="!newName.trim() || creating"
            class="bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
            @click="handleCreate"
          >
            {{ creating ? 'Creating…' : 'Create' }}
          </button>
          <button
            class="text-gray-400 hover:text-gray-600 px-2"
            @click="showCreate = false; newName = ''"
          >
            ✕
          </button>
        </div>
        <p v-if="createError" class="text-red-500 text-xs mt-2">{{ createError }}</p>
      </div>

      <!-- Loading -->
      <div v-if="containerStore.loading" class="flex justify-center py-16">
        <span class="animate-spin w-8 h-8 border-2 border-gray-200 border-t-indigo-600 rounded-full" />
      </div>

      <!-- Error -->
      <p v-else-if="containerStore.error" class="text-red-500 text-sm">{{ containerStore.error }}</p>

      <!-- Container list -->
      <div v-else-if="containerStore.items.length > 0" class="flex flex-col gap-3">
        <div
          v-for="container in containerStore.items"
          :key="container.id"
          class="bg-white rounded-xl shadow-sm p-5 flex items-center gap-4 cursor-pointer hover:shadow-md transition-shadow"
          @click="router.push(`/evidence/${container.id}`)"
        >
          <div class="w-12 h-12 rounded-xl bg-indigo-100 flex items-center justify-center text-indigo-600 text-xl shrink-0">
            📁
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-semibold text-gray-900 truncate">{{ container.name }}</p>
            <p class="text-xs text-gray-400 mt-0.5">Created {{ formatDate(container.created_at) }}</p>
          </div>
          <div class="flex items-center gap-3 shrink-0">
            <span class="text-indigo-600 text-sm font-medium hidden sm:inline">View →</span>
            <button
              class="text-xs text-red-400 hover:text-red-600 transition-colors p-1"
              @click.stop="handleDelete(container.id)"
              title="Delete container"
            >
              🗑
            </button>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-else class="text-center py-20">
        <div class="text-6xl mb-4">📂</div>
        <p class="text-gray-500 text-lg font-medium">No evidence containers yet.</p>
        <p class="text-gray-400 text-sm mt-1">Create a container to start organising your evidence.</p>
        <button
          class="mt-5 bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-lg text-sm font-semibold transition-colors"
          @click="showCreate = true"
        >
          Create your first container
        </button>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useContainerStore } from '../stores/containers'

const router = useRouter()
const containerStore = useContainerStore()

const showCreate = ref(false)
const newName = ref('')
const creating = ref(false)
const createError = ref('')
const nameInput = ref<HTMLInputElement | null>(null)

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

async function handleCreate() {
  const name = newName.value.trim()
  if (!name) return
  creating.value = true
  createError.value = ''
  try {
    const container = await containerStore.createContainer(name)
    showCreate.value = false
    newName.value = ''
    router.push(`/evidence/${container.id}`)
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    createError.value = err.response?.data?.error ?? 'Failed to create container'
  } finally {
    creating.value = false
  }
}

async function handleDelete(id: string) {
  if (!confirm('Delete this container and all its evidence? This cannot be undone.')) return
  try {
    await containerStore.deleteContainer(id)
  } catch {
    alert('Failed to delete container.')
  }
}

onMounted(() => {
  containerStore.fetchContainers()
})
</script>
