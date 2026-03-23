<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { useChatStore } from '@/stores/chat'
import ChatMessage from '@/components/ChatMessage.vue'
import ChatInput from '@/components/ChatInput.vue'
import { ScrollArea } from '@/components/ui/scroll-area'
import { BotIcon } from 'lucide-vue-next'

const store = useChatStore()
const bottomRef = ref<HTMLElement | null>(null)

function scrollToBottom() {
  nextTick(() => {
    bottomRef.value?.scrollIntoView({ behavior: 'smooth' })
  })
}

watch(
  () => store.activeConversation?.messages.length,
  () => scrollToBottom(),
)

watch(
  () => store.activeConversation?.messages.at(-1)?.content,
  () => scrollToBottom(),
)
</script>

<template>
  <div class="flex flex-1 flex-col overflow-hidden bg-zinc-900">
    <!-- Empty state -->
    <div
      v-if="!store.activeConversation || store.activeConversation.messages.length === 0"
      class="flex flex-1 flex-col items-center justify-center gap-4 text-zinc-500"
    >
      <BotIcon class="h-12 w-12 opacity-40" />
      <p class="text-sm">How can I help you today?</p>
    </div>

    <!-- Messages -->
    <ScrollArea v-else class="flex-1">
      <div class="mx-auto max-w-3xl">
        <ChatMessage
          v-for="msg in store.activeConversation.messages"
          :key="msg.id"
          :message="msg"
        />
        <div ref="bottomRef" class="h-4" />
      </div>
    </ScrollArea>

    <ChatInput />
  </div>
</template>
