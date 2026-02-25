import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Evidence } from '../types'
import api from '../api'

export const useEvidenceStore = defineStore('evidence', () => {
  const items = ref<Evidence[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchByContainer(containerId: string) {
    loading.value = true
    error.value = null
    try {
      const response = await api.get<Evidence[]>(`/containers/${containerId}/evidence`)
      items.value = response.data
    } catch (e: unknown) {
      const err = e as { response?: { data?: { error?: string } } }
      error.value = err.response?.data?.error ?? 'Failed to fetch evidence'
    } finally {
      loading.value = false
    }
  }

  async function uploadEvidence(formData: FormData): Promise<Evidence> {
    const response = await api.post<Evidence>('/evidence', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    items.value.unshift(response.data)
    return response.data
  }

  async function deleteEvidence(id: string) {
    await api.delete(`/evidence/${id}`)
    items.value = items.value.filter((e) => e.id !== id)
  }

  function clear() {
    items.value = []
    error.value = null
  }

  return { items, loading, error, fetchByContainer, uploadEvidence, deleteEvidence, clear }
})
