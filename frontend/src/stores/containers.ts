import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { EvidenceContainer } from '../types'
import api from '../api'

export const useContainerStore = defineStore('containers', () => {
  const items = ref<EvidenceContainer[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchContainers() {
    loading.value = true
    error.value = null
    try {
      const response = await api.get<EvidenceContainer[]>('/containers')
      items.value = response.data
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } } }
      error.value = err.response?.data?.error ?? 'Failed to fetch containers'
    } finally {
      loading.value = false
    }
  }

  async function createContainer(name: string): Promise<EvidenceContainer> {
    const response = await api.post<EvidenceContainer>('/containers', { name })
    items.value.unshift(response.data)
    return response.data
  }

  async function deleteContainer(id: string) {
    await api.delete(`/containers/${id}`)
    items.value = items.value.filter((c) => c.id !== id)
  }

  return { items, loading, error, fetchContainers, createContainer, deleteContainer }
})
