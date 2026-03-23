<script setup lang="ts">
import ChatSidebar from '@/components/ChatSidebar.vue'
import ChatWindow from '@/components/ChatWindow.vue'
import { useChatStore } from '@/stores/chat'

const store = useChatStore()
if (store.conversations.length === 0) {
  store.newConversation()
}
</script>

<template>
  <div class="flex h-screen overflow-hidden bg-zinc-950 text-zinc-100">
    <ChatSidebar />
    <main class="flex flex-1 flex-col overflow-hidden">
      <ChatWindow />
    </main>
  </div>
</template>
