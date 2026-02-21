import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { User, Message, WSMessage } from '../types'
import api from '../api'

export const useChatStore = defineStore('chat', () => {
  const users = ref<User[]>([])
  const selectedUser = ref<User | null>(null)
  const messages = ref<Record<string, Message[]>>({})
  const socket = ref<WebSocket | null>(null)

  async function fetchUsers() {
    const response = await api.get<User[]>('/users')
    users.value = response.data
  }

  function selectUser(user: User) {
    selectedUser.value = user
  }

  async function fetchMessages(userId: string) {
    const response = await api.get<Message[]>(`/messages/${userId}`)
    messages.value[userId] = response.data
  }

  async function sendMessage(content: string) {
    if (!selectedUser.value) return
    const response = await api.post<Message>('/messages', {
      recipient_id: selectedUser.value.id,
      content,
    })
    const uid = selectedUser.value.id
    if (!messages.value[uid]) messages.value[uid] = []
    messages.value[uid].push(response.data)
  }

  function connectWebSocket(token: string) {
    const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const url = `${proto}//${window.location.host}/ws?token=${token}`
    socket.value = new WebSocket(url)

    socket.value.onmessage = (event: MessageEvent) => {
      try {
        const msg = JSON.parse(event.data as string) as WSMessage
        if (msg.type === 'message') handleIncoming(msg.data)
      } catch {
        // ignore malformed frames
      }
    }

    socket.value.onerror = (e) => console.error('ws error', e)
    socket.value.onclose = () => console.log('ws closed')
  }

  function handleIncoming(msg: Message) {
    const key = msg.sender_id
    if (!messages.value[key]) messages.value[key] = []
    if (!messages.value[key].some((m) => m.id === msg.id)) {
      messages.value[key].push(msg)
    }
  }

  function disconnectWebSocket() {
    socket.value?.close()
    socket.value = null
  }

  return {
    users,
    selectedUser,
    messages,
    socket,
    fetchUsers,
    selectUser,
    fetchMessages,
    sendMessage,
    connectWebSocket,
    disconnectWebSocket,
  }
})
