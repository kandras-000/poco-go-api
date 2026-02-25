<template>
  <div class="bg-white rounded-xl shadow-sm p-6">
    <h2 class="text-lg font-semibold text-gray-900 mb-5">Upload Evidence</h2>

    <!-- Drop zone -->
    <div
      class="border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors"
      :class="isDragging ? 'border-indigo-500 bg-indigo-50' : 'border-gray-300 hover:border-indigo-400'"
      @dragover.prevent="isDragging = true"
      @dragleave="isDragging = false"
      @drop.prevent="handleDrop"
      @click="fileInput?.click()"
    >
      <input
        ref="fileInput"
        type="file"
        class="hidden"
        accept="image/*,video/*,audio/*,.pdf,.doc,.docx"
        capture
        @change="handleFileChange"
      />
      <div v-if="!selectedFile">
        <div class="text-4xl mb-3">📎</div>
        <p class="text-gray-600 font-medium">Drag & drop or tap to upload</p>
        <p class="text-gray-400 text-sm mt-1">Images, video, audio, PDF, Word documents</p>
      </div>
      <div v-else class="flex flex-col items-center gap-3">
        <!-- Preview -->
        <img
          v-if="previewUrl && selectedFile.type.startsWith('image/')"
          :src="previewUrl"
          class="max-h-40 rounded-lg object-contain"
          alt="Preview"
        />
        <video
          v-else-if="previewUrl && selectedFile.type.startsWith('video/')"
          :src="previewUrl"
          class="max-h-40 rounded-lg"
          controls
        />
        <div v-else class="text-5xl">
          {{ fileIcon(selectedFile.type) }}
        </div>
        <div class="text-sm text-gray-700 font-medium">{{ selectedFile.name }}</div>
        <div class="text-xs text-gray-400">{{ formatSize(selectedFile.size) }}</div>
        <button
          type="button"
          class="text-xs text-indigo-600 hover:underline"
          @click.stop="clearFile"
        >
          Change file
        </button>
      </div>
    </div>

    <!-- Description -->
    <div class="mt-4">
      <label class="block text-sm text-gray-600 font-medium mb-1">Description (optional)</label>
      <textarea
        v-model="description"
        rows="2"
        placeholder="Add context about this evidence…"
        class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm outline-none focus:border-indigo-500 transition-colors resize-none"
      />
    </div>

    <!-- Geolocation toggle -->
    <div class="mt-4 flex items-center gap-3">
      <button
        type="button"
        class="flex items-center gap-2 text-sm font-medium transition-colors"
        :class="useLocation ? 'text-indigo-600' : 'text-gray-500'"
        @click="toggleLocation"
      >
        <span
          class="w-10 h-5 rounded-full transition-colors flex items-center"
          :class="useLocation ? 'bg-indigo-600' : 'bg-gray-300'"
        >
          <span
            class="w-4 h-4 rounded-full bg-white shadow transition-transform mx-0.5"
            :class="useLocation ? 'translate-x-5' : 'translate-x-0'"
          />
        </span>
        Include location
      </button>
      <span v-if="locationStatus" class="text-xs text-gray-500">{{ locationStatus }}</span>
    </div>

    <!-- Error -->
    <p v-if="uploadError" class="mt-3 text-sm text-red-500">{{ uploadError }}</p>

    <!-- Upload button -->
    <button
      type="button"
      :disabled="!selectedFile || uploading"
      class="mt-5 w-full py-2.5 bg-indigo-600 text-white rounded-lg font-semibold text-sm hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
      @click="handleUpload"
    >
      <span v-if="uploading" class="animate-spin w-4 h-4 border-2 border-white/30 border-t-white rounded-full" />
      {{ uploading ? 'Uploading…' : 'Upload Evidence' }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useEvidenceStore } from '../stores/evidence'

const emit = defineEmits<{ uploaded: [] }>()

const evidenceStore = useEvidenceStore()

const fileInput = ref<HTMLInputElement | null>(null)
const selectedFile = ref<File | null>(null)
const previewUrl = ref<string | null>(null)
const description = ref('')
const useLocation = ref(false)
const locationStatus = ref('')
const latitude = ref<number | null>(null)
const longitude = ref<number | null>(null)
const uploading = ref(false)
const uploadError = ref('')
const isDragging = ref(false)

function handleFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files?.[0]) setFile(input.files[0])
}

function handleDrop(e: DragEvent) {
  isDragging.value = false
  if (e.dataTransfer?.files?.[0]) setFile(e.dataTransfer.files[0])
}

function setFile(file: File) {
  selectedFile.value = file
  uploadError.value = ''
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  if (file.type.startsWith('image/') || file.type.startsWith('video/')) {
    previewUrl.value = URL.createObjectURL(file)
  } else {
    previewUrl.value = null
  }
}

function clearFile() {
  selectedFile.value = null
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = null
  if (fileInput.value) fileInput.value.value = ''
}

function fileIcon(mime: string): string {
  if (mime.startsWith('audio/')) return '🎵'
  if (mime.includes('pdf')) return '📄'
  if (mime.includes('word') || mime.includes('document')) return '📝'
  return '📁'
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

async function toggleLocation() {
  useLocation.value = !useLocation.value
  if (!useLocation.value) {
    latitude.value = null
    longitude.value = null
    locationStatus.value = ''
    return
  }
  locationStatus.value = 'Getting location…'
  try {
    const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
      navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 10000 }),
    )
    latitude.value = pos.coords.latitude
    longitude.value = pos.coords.longitude
    locationStatus.value = `${pos.coords.latitude.toFixed(5)}, ${pos.coords.longitude.toFixed(5)}`
  } catch {
    useLocation.value = false
    latitude.value = null
    longitude.value = null
    locationStatus.value = 'Location unavailable'
  }
}

async function handleUpload() {
  if (!selectedFile.value) return
  uploading.value = true
  uploadError.value = ''
  try {
    const fd = new FormData()
    fd.append('file', selectedFile.value)
    fd.append('description', description.value)
    if (latitude.value !== null) fd.append('latitude', String(latitude.value))
    if (longitude.value !== null) fd.append('longitude', String(longitude.value))
    await evidenceStore.uploadEvidence(fd)
    clearFile()
    description.value = ''
    useLocation.value = false
    latitude.value = null
    longitude.value = null
    locationStatus.value = ''
    emit('uploaded')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    uploadError.value = err.response?.data?.error ?? 'Upload failed'
  } finally {
    uploading.value = false
  }
}
</script>
