export async function streamChat(
  message: string,
  conversationHistory: { role: string; content: string }[],
  onChunk: (chunk: string) => void,
): Promise<void> {
  const response = await fetch(`${import.meta.env.VITE_API_URL}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, conversationHistory }),
  })

  if (!response.ok) throw new Error(`HTTP error: ${response.status}`)

  const reader = response.body!.getReader()
  const decoder = new TextDecoder()

  while (true) {
    const { done, value } = await reader.read()
    if (done) break

    const text = decoder.decode(value, { stream: true })
    const lines = text.split('\n')
    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = line.slice(6)
        if (data === '[DONE]') return
        onChunk(data)
      }
    }
  }
}
