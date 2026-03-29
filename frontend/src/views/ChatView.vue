<script setup lang="ts">
import { ref } from 'vue'
import ChatSidebar from '@/components/ChatSidebar.vue'
import ChatWindow from '@/components/ChatWindow.vue'
import { useChatStore } from '@/stores/chat'

const store = useChatStore()
if (store.conversations.length === 0) {
  store.newConversation()
}

const sidebarOpen = ref(false)
</script>

<template>
  <div class="flex h-screen overflow-hidden bg-zinc-950 text-zinc-100">
    <!-- Mobile overlay backdrop -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-20 bg-black/50 lg:hidden"
      @click="sidebarOpen = false"
    />

    <ChatSidebar :open="sidebarOpen" @close="sidebarOpen = false" />

    <main class="flex flex-1 flex-col overflow-hidden">
      <ChatWindow @toggle-sidebar="sidebarOpen = !sidebarOpen" />
    </main>
  </div>
</template>
