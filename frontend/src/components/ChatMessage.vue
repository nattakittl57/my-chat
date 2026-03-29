<script setup lang="ts">
import type { Message } from '@/stores/chat'
import MarkdownRenderer from './MarkdownRenderer.vue'
import { BotIcon, UserIcon } from 'lucide-vue-next'

const props = defineProps<{ message: Message }>()
</script>

<template>
  <div
    class="flex gap-3 px-4 py-5"
    :class="props.message.role === 'user' ? 'flex-row-reverse' : 'flex-row'"
  >
    <!-- Avatar -->
    <div
      class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
      :class="props.message.role === 'user' ? 'bg-violet-600' : 'bg-emerald-600'"
    >
      <UserIcon v-if="props.message.role === 'user'" class="h-4 w-4 text-white" />
      <BotIcon v-else class="h-4 w-4 text-white" />
    </div>

    <!-- Bubble -->
    <div
      class="max-w-[85%] sm:max-w-[80%] rounded-2xl px-4 py-3 text-sm leading-relaxed"
      :class="
        props.message.role === 'user' ? 'bg-violet-600 text-white' : 'bg-zinc-700 text-zinc-100'
      "
    >
      <MarkdownRenderer
        v-if="props.message.role === 'assistant'"
        :content="props.message.content"
      />
      <span v-else class="whitespace-pre-wrap">{{ props.message.content }}</span>
    </div>
  </div>
</template>
