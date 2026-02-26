<template>
  <div class="flex-1 flex items-center justify-center bg-gray-100">
    <div class="bg-white rounded-xl px-8 py-10 w-full max-w-md shadow-lg mx-4">
      <h1 class="text-center text-indigo-600 text-2xl font-bold mb-1">Case Builder</h1>
      <h2 class="text-center text-lg text-gray-500 font-medium mb-7">Sign In</h2>
      <form @submit.prevent="handleLogin">
        <div class="mb-4">
          <label class="block text-sm text-gray-500 mb-1">Email</label>
          <input
            v-model="email"
            type="email"
            placeholder="you@example.com"
            required
            class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm outline-none focus:border-indigo-500 transition-colors"
          />
        </div>
        <div class="mb-4">
          <label class="block text-sm text-gray-500 mb-1">Password</label>
          <input
            v-model="password"
            type="password"
            placeholder="••••••••"
            required
            class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm outline-none focus:border-indigo-500 transition-colors"
          />
        </div>
        <p v-if="error" class="text-red-500 text-sm mb-3">{{ error }}</p>
        <button
          type="submit"
          :disabled="loading"
          class="w-full py-2.5 bg-indigo-600 text-white border-none rounded-lg text-base font-medium mt-2 cursor-pointer hover:bg-indigo-700 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
        >
          {{ loading ? 'Signing in…' : 'Sign In' }}
        </button>
      </form>
      <p class="text-center mt-5 text-sm text-gray-500">
        No account?
        <RouterLink to="/register" class="text-indigo-600 font-semibold no-underline hover:underline">
          Create one
        </RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function handleLogin() {
  error.value = ''
  loading.value = true
  try {
    await auth.login(email.value, password.value)
    router.push('/chat')
  } catch (e: unknown) {
    const err = e as { response?: { data?: { error?: string } } }
    error.value = err.response?.data?.error ?? 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>
