export interface User {
  id: string
  username: string
  email: string
  created_at: string
}

export interface Message {
  id: string
  sender_id: string
  sender_username: string
  recipient_id: string
  content: string
  delivered: boolean
  created_at: string
}

export interface WSMessage {
  type: 'message'
  data: Message
}

export interface AuthResponse {
  token: string
  user: User
}

export interface Evidence {
  id: string
  user_id: string
  filename: string
  original_name: string
  mime_type: string
  file_size: number
  description: string | null
  latitude: number | null
  longitude: number | null
  created_at: string
}
