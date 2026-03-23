<script setup lang="ts">
const props = defineProps<{ content: string }>()

interface Part {
  type: 'text' | 'code'
  text: string
}

function parseParts(content: string): Part[] {
  const parts: Part[] = []
  const regex = /```[\w]*\n?([\s\S]*?)```/g
  let last = 0
  let match: RegExpExecArray | null

  while ((match = regex.exec(content)) !== null) {
    if (match.index > last) {
      parts.push({ type: 'text', text: content.slice(last, match.index) })
    }
    parts.push({ type: 'code', text: match[1] ?? '' })
    last = match.index + match[0].length
  }

  if (last < content.length) {
    parts.push({ type: 'text', text: content.slice(last) })
  }

  return parts
}
</script>

<template>
  <div class="prose-sm prose-invert max-w-none space-y-2 whitespace-pre-wrap break-words">
    <template v-for="(part, i) in parseParts(props.content)" :key="i">
      <pre
        v-if="part.type === 'code'"
        class="overflow-x-auto rounded-md bg-zinc-900 p-3 font-mono text-xs"
      ><code>{{ part.text }}</code></pre>
      <span v-else>{{ part.text }}</span>
    </template>
  </div>
</template>
