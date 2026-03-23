<script setup lang="ts">
import { ref } from 'vue'
import { useChatStore } from '@/stores/chat'
import { Textarea } from '@/components/ui/textarea'
import { Button } from '@/components/ui/button'
import { SendHorizontalIcon } from 'lucide-vue-next'

const store = useChatStore()
const input = ref('')

async function send() {
  const text = input.value.trim()
  if (!text || store.isStreaming) return
  input.value = ''
  await store.sendMessage(text)
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    send()
  }
}
</script>

<template>
  <div class="border-t border-zinc-700 bg-zinc-900 p-4">
    <div class="mx-auto flex max-w-3xl items-end gap-3">
      <Textarea
        v-model="input"
        placeholder="Send a message... (Shift+Enter for newline)"
        class="min-h-[44px] max-h-48 flex-1 resize-none bg-zinc-800 text-zinc-100 placeholder:text-zinc-500 border-zinc-700 focus-visible:ring-zinc-500"
        rows="1"
        @keydown="onKeydown"
      />
      <Button
        :disabled="!input.trim() || store.isStreaming"
        class="h-11 w-11 shrink-0 bg-violet-600 p-0 hover:bg-violet-700 disabled:opacity-40"
        @click="send"
      >
        <SendHorizontalIcon class="h-4 w-4" />
      </Button>
    </div>
  </div>
</template>
