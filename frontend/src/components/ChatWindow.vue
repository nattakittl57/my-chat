<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { useChatStore } from '@/stores/chat'
import ChatMessage from '@/components/ChatMessage.vue'
import ChatInput from '@/components/ChatInput.vue'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Button } from '@/components/ui/button'
import { BotIcon, MenuIcon } from 'lucide-vue-next'

const emit = defineEmits<{ toggleSidebar: [] }>()

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
    <!-- Mobile / tablet header -->
    <header class="flex items-center gap-3 border-b border-zinc-700 px-4 py-3 lg:hidden">
      <Button
        variant="ghost"
        size="icon"
        class="shrink-0 text-zinc-400 hover:text-white"
        @click="emit('toggleSidebar')"
      >
        <MenuIcon class="h-5 w-5" />
      </Button>
      <span class="truncate text-sm font-medium text-zinc-300">
        {{ store.activeConversation?.title ?? 'Chat' }}
      </span>
    </header>

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
