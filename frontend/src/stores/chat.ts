import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { streamChat } from '@/services/api'

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: Date
}

export interface Conversation {
  id: string
  title: string
  messages: Message[]
}

export const useChatStore = defineStore('chat', () => {
  const conversations = ref<Conversation[]>([])
  const activeConversationId = ref<string | null>(null)
  const isStreaming = ref(false)

  const activeConversation = computed(
    () => conversations.value.find((c) => c.id === activeConversationId.value) ?? null,
  )

  function newConversation() {
    const id = crypto.randomUUID()
    conversations.value.unshift({ id, title: 'New Chat', messages: [] })
    activeConversationId.value = id
  }

  function selectConversation(id: string) {
    activeConversationId.value = id
  }

  function deleteConversation(id: string) {
    conversations.value = conversations.value.filter((c) => c.id !== id)
    if (activeConversationId.value === id) {
      activeConversationId.value = conversations.value[0]?.id ?? null
    }
  }

  async function sendMessage(content: string) {
    if (!activeConversationId.value) newConversation()
    const conversation = activeConversation.value!

    const userMessage: Message = {
      id: crypto.randomUUID(),
      role: 'user',
      content,
      timestamp: new Date(),
    }
    conversation.messages.push(userMessage)

    if (conversation.messages.length === 1) {
      conversation.title = content.slice(0, 40)
    }

    const assistantId = crypto.randomUUID()
    conversation.messages.push({
      id: assistantId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
    })

    isStreaming.value = true

    const history = conversation.messages
      .slice(0, -1)
      .map((m) => ({ role: m.role, content: m.content }))

    try {
      await streamChat(content, history, (chunk) => {
        const msg = conversation.messages.find((m) => m.id === assistantId)
        if (msg) msg.content += chunk
      })
    } finally {
      isStreaming.value = false
    }
  }

  return {
    conversations,
    activeConversationId,
    activeConversation,
    isStreaming,
    newConversation,
    selectConversation,
    deleteConversation,
    sendMessage,
  }
})
