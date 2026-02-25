<template>
  <div class="flex-1 overflow-y-auto bg-gray-100">
    <div class="max-w-4xl mx-auto px-4 py-8">
      <EvidenceUpload @uploaded="evidenceStore.fetchEvidence()" />
      <div class="mt-8">
        <EvidenceList />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useEvidenceStore } from '../stores/evidence'
import EvidenceUpload from '../components/EvidenceUpload.vue'
import EvidenceList from '../components/EvidenceList.vue'

const evidenceStore = useEvidenceStore()

onMounted(() => {
  evidenceStore.fetchEvidence()
})
</script>
