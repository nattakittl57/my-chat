<script setup lang="ts">
import { useChatStore } from '@/stores/chat'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import { PlusIcon, TrashIcon, MessageSquareIcon } from 'lucide-vue-next'

const store = useChatStore()
</script>

<template>
  <aside class="flex h-full w-64 flex-col bg-zinc-800 py-3">
    <div class="px-3">
      <Button
        class="w-full justify-start gap-2 bg-zinc-700 text-white hover:bg-zinc-600"
        @click="store.newConversation()"
      >
        <PlusIcon class="h-4 w-4" />
        New Chat
      </Button>
    </div>

    <Separator class="my-3 bg-zinc-700" />

    <ScrollArea class="flex-1 px-2">
      <div class="space-y-1">
        <button
          v-for="conv in store.conversations"
          :key="conv.id"
          class="group flex w-full items-center justify-between rounded-md px-3 py-2 text-left text-sm text-zinc-300 hover:bg-zinc-700"
          :class="{ 'bg-zinc-700 text-white': conv.id === store.activeConversationId }"
          @click="store.selectConversation(conv.id)"
        >
          <span class="flex items-center gap-2 truncate">
            <MessageSquareIcon class="h-3.5 w-3.5 shrink-0 opacity-60" />
            <span class="truncate">{{ conv.title }}</span>
          </span>
          <TrashIcon
            class="h-3.5 w-3.5 shrink-0 opacity-0 transition-opacity group-hover:opacity-60 hover:!opacity-100"
            @click.stop="store.deleteConversation(conv.id)"
          />
        </button>
      </div>
    </ScrollArea>
  </aside>
</template>
