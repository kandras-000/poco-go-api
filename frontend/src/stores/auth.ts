import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, AuthResponse } from '../types'
import api from '../api'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem('token'))
  const storedUser = localStorage.getItem('user')
  const user = ref<User | null>(storedUser ? (JSON.parse(storedUser) as User) : null)

  const isAuthenticated = computed(() => !!token.value)

  async function login(email: string, password: string) {
    const response = await api.post<AuthResponse>('/auth/login', { email, password })
    token.value = response.data.token
    user.value = response.data.user
    localStorage.setItem('token', response.data.token)
    localStorage.setItem('user', JSON.stringify(response.data.user))
  }

  async function register(username: string, email: string, password: string) {
    const response = await api.post<AuthResponse>('/auth/register', { username, email, password })
    token.value = response.data.token
    user.value = response.data.user
    localStorage.setItem('token', response.data.token)
    localStorage.setItem('user', JSON.stringify(response.data.user))
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  return { token, user, isAuthenticated, login, register, logout }
})
