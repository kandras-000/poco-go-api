<template>
  <div class="auth-page">
    <div class="auth-card">
      <h1 class="logo">Poco Chat</h1>
      <h2>Sign In</h2>
      <form @submit.prevent="handleLogin">
        <div class="field">
          <label>Email</label>
          <input v-model="email" type="email" placeholder="you@example.com" required />
        </div>
        <div class="field">
          <label>Password</label>
          <input v-model="password" type="password" placeholder="••••••••" required />
        </div>
        <p v-if="error" class="error">{{ error }}</p>
        <button type="submit" :disabled="loading" class="btn-primary">
          {{ loading ? 'Signing in…' : 'Sign In' }}
        </button>
      </form>
      <p class="switch-link">
        No account? <RouterLink to="/register">Create one</RouterLink>
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

<style scoped>
.auth-page {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f0f2f5;
}

.auth-card {
  background: #fff;
  border-radius: 12px;
  padding: 2.5rem 2rem;
  width: 100%;
  max-width: 400px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.08);
}

.logo {
  text-align: center;
  color: #4f46e5;
  margin-bottom: 0.25rem;
  font-size: 1.6rem;
}

h2 {
  text-align: center;
  font-size: 1.1rem;
  color: #555;
  margin-bottom: 1.75rem;
  font-weight: 500;
}

.field {
  margin-bottom: 1rem;
}

label {
  display: block;
  font-size: 0.85rem;
  color: #555;
  margin-bottom: 0.3rem;
}

input {
  width: 100%;
  padding: 0.6rem 0.8rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 0.95rem;
  transition: border-color 0.15s;
}

input:focus {
  outline: none;
  border-color: #4f46e5;
}

.error {
  color: #e53e3e;
  font-size: 0.85rem;
  margin-bottom: 0.75rem;
}

.btn-primary {
  width: 100%;
  padding: 0.7rem;
  background: #4f46e5;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: background 0.15s;
  margin-top: 0.5rem;
}

.btn-primary:hover:not(:disabled) {
  background: #4338ca;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.switch-link {
  text-align: center;
  margin-top: 1.25rem;
  font-size: 0.875rem;
  color: #666;
}

.switch-link a {
  color: #4f46e5;
  text-decoration: none;
  font-weight: 600;
}
</style>
