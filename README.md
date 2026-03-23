# My Chat AI

Web-based AI chat application styled like ChatGPT, powered by Azure OpenAI.

## Tech Stack

| Layer    | Technology                                                  |
| -------- | ----------------------------------------------------------- |
| Frontend | Vue 3, TypeScript, Vite, Pinia, shadcn-vue, Tailwind CSS v4 |
| Backend  | .NET 8 Web API (Controller-based)                           |
| AI       | Azure OpenAI (streaming via SSE)                            |

---

## How It Works

### Request Flow

```
User types message
       │
       ▼
ChatInput.vue (keydown Enter / click send)
       │
       ▼
store.sendMessage()            ← Pinia (chat.ts)
  ├── push user message
  ├── push empty assistant message
  └── call streamChat()
       │
       ▼
fetch POST /api/chat           ← native fetch (api.ts)
  body: { message, conversationHistory }
       │
       ▼
ChatController.SendMessage()   ← .NET 8 (ChatController.cs)
       │
       ▼
ChatService.StreamAsync()      ← IAsyncEnumerable<string>
       │
       ▼
AzureOpenAIClient
  CompleteChatStreamingAsync() ← Azure OpenAI
       │
       ▼
SSE stream: data: <token>\n\n  ← text/event-stream
       │
       ▼
frontend reads SSE chunks
  msg.content += chunk         ← Vue reactive update
       │
       ▼
ChatMessage.vue re-renders     ← MarkdownRenderer parses code blocks
```

### Conversation History

Every request includes the full conversation history so the model maintains context:

```
[{ role: "user",      content: "Hello" },
 { role: "assistant", content: "Hi there!" },
 { role: "user",      content: "What is TypeScript?" }]
```

---

## Project Structure

```
my-chat/
├── backend/
│   ├── Controllers/
│   │   └── ChatController.cs       POST /api/chat → SSE
│   ├── Services/
│   │   └── ChatService.cs          Azure OpenAI streaming
│   ├── Interfaces/
│   │   └── IChatService.cs
│   ├── Models/
│   │   ├── ChatRequest.cs
│   │   └── ChatMessageDto.cs
│   ├── Program.cs                  DI, CORS, middleware
│   └── appsettings.json            Azure OpenAI config
│
└── frontend/
    └── src/
        ├── views/
        │   └── ChatView.vue        root layout
        ├── components/
        │   ├── ChatSidebar.vue     conversation list + New Chat
        │   ├── ChatWindow.vue      message thread
        │   ├── ChatMessage.vue     user/assistant bubble
        │   ├── ChatInput.vue       textarea + send
        │   └── MarkdownRenderer.vue  code block parser
        ├── stores/
        │   └── chat.ts             Pinia store
        └── services/
            └── api.ts              streamChat() via fetch SSE
```

---

## Getting Started

### 1. Configure Azure OpenAI

Edit `backend/appsettings.json`:

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://<your-resource>.openai.azure.com/",
    "ApiKey": "<your-api-key>",
    "DeploymentName": "gpt-4o"
  }
}
```

> **Important**: Use the base URL only — do not include `/openai/responses` or query strings.

### 2. Run Backend

```bash
cd backend
dotnet run --launch-profile http
# Listening on http://localhost:5000
```

### 3. Run Frontend

```bash
cd frontend
npm install
npm run dev
# http://localhost:5173
```
