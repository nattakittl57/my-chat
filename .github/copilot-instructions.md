# Copilot Instructions — My Chat AI

## Project Overview

Web-based AI chat application (no authentication required).

- **Frontend**: Vue 3 + TypeScript + Vite, UI styled like ChatGPT, components from **shadcn-vue**
- **Backend**: **.NET 8 Web API** using **Controller-based** routing (not Minimal API)

---

## Architecture

```
my-chat/
├── frontend/          # Vue 3 + Vite + shadcn-vue
└── backend/           # .NET 8 Web API (Controllers)
```

---

## Tech Stack

### Frontend

| Package           | Version                  | Purpose              |
| ----------------- | ------------------------ | -------------------- |
| `vue`             | ^3.5                     | UI framework         |
| `vite`            | ^7                       | Build tool           |
| `typescript`      | ~5.9                     | Type safety          |
| `pinia`           | latest                   | State management     |
| `vue-router`      | ^5                       | Routing              |
| `shadcn-vue`      | ^2                       | UI component library |
| `tailwindcss`     | v4 (`@tailwindcss/vite`) | Utility CSS          |
| `lucide-vue-next` | latest                   | Icons                |

### Backend

| Package           | Version      | Purpose          |
| ----------------- | ------------ | ---------------- |
| `.NET`            | 8.0          | Runtime          |
| `Azure.AI.OpenAI` | 2.9.0-beta.1 | Azure OpenAI SDK |

---

## Backend (.NET 8 Web API)

### Rules

- Use **Controller-based** pattern — do NOT use Minimal API / `app.MapGet()`
- Controllers go in `Controllers/` folder and inherit from `ControllerBase`
- Use `[ApiController]` and `[Route("api/[controller]")]` attributes
- Use named CORS policy `"AllowFrontend"` — call `app.UseRouting()` before `app.UseCors()`
- Use `services.AddControllers()` and `app.MapControllers()`
- Target framework: `net8.0`
- Use **dependency injection** for services
- Services go in `Services/` folder with interfaces in `Interfaces/`
- Models/DTOs go in `Models/` folder

### Azure OpenAI Configuration (`appsettings.json`)

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://<your-resource>.openai.azure.com/",
    "ApiKey": "",
    "DeploymentName": "gpt-4o"
  }
}
```

### DI Registration (`Program.cs`)

```csharp
const string CorsPolicy = "AllowFrontend";
builder.Services.AddCors(options =>
    options.AddPolicy(CorsPolicy, p =>
        p.WithOrigins("http://localhost:5173").AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddSingleton(new AzureOpenAIClient(
    new Uri(builder.Configuration["AzureOpenAI:Endpoint"]!),
    new AzureKeyCredential(builder.Configuration["AzureOpenAI:ApiKey"]!)
));
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddControllers();

// middleware order matters
app.UseRouting();
app.UseCors(CorsPolicy);
app.MapControllers();
```

### ChatService Pattern

```csharp
public async IAsyncEnumerable<string> StreamAsync(IEnumerable<ChatMessageDto> history, string newMessage)
{
    var messages = history.Select<ChatMessageDto, ChatMessage>(m =>
        m.Role == "user" ? new UserChatMessage(m.Content) : new AssistantChatMessage(m.Content)
    ).Append(new UserChatMessage(newMessage)).ToList();

    await foreach (var update in _client.GetChatClient(_deployment).CompleteChatStreamingAsync(messages))
        foreach (var part in update.ContentUpdate)
            if (!string.IsNullOrEmpty(part.Text))
                yield return part.Text;
}
```

### Controller — SSE Streaming

```csharp
[HttpPost]
[EnableCors("AllowFrontend")]
public async Task SendMessage([FromBody] ChatRequest request, CancellationToken cancellationToken)
{
    Response.ContentType = "text/event-stream";
    Response.Headers.CacheControl = "no-cache";
    await foreach (var chunk in _chatService.StreamAsync(...).WithCancellation(cancellationToken))
    {
        await Response.Body.WriteAsync(Encoding.UTF8.GetBytes($"data: {chunk}\n\n"), cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);
    }
}
```

---

## Frontend (Vue 3 + shadcn-vue)

### Rules

- Use **Vue 3** with `<script setup lang="ts">` (Composition API)
- Use **shadcn-vue** for ALL UI components — import from `@/components/ui/`
- Use **Tailwind CSS v4** — configured via `@tailwindcss/vite` plugin (no `tailwind.config.js`)
- CSS entry: `src/assets/main.css` with `@import "tailwindcss";`
- State management: **Pinia** stores in `src/stores/`
- API calls: native `fetch` for SSE streaming, base URL from `import.meta.env.VITE_API_URL`
- Router: **Vue Router 4** in `src/router/index.ts`
- Icons: **lucide-vue-next**

### Project Structure

```
src/
├── components/
│   ├── ui/                   # shadcn-vue auto-generated
│   ├── ChatSidebar.vue       # sidebar with conversation list + New Chat
│   ├── ChatWindow.vue        # message thread + scroll
│   ├── ChatMessage.vue       # bubble (user right / assistant left)
│   ├── ChatInput.vue         # textarea + send button
│   └── MarkdownRenderer.vue  # parse code blocks from AI response
├── stores/
│   └── chat.ts               # Pinia — conversations, messages, streaming
├── views/
│   └── ChatView.vue          # root layout
└── services/
    └── api.ts                # streamChat() using native fetch + SSE
```

### Pinia Store Shape

```ts
interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}
interface Conversation {
  id: string;
  title: string;
  messages: Message[];
}
```

> Track streaming message by `id` (not array index) to avoid `noUncheckedIndexedAccess` errors:
>
> ```ts
> const assistantId = crypto.randomUUID();
> conversation.messages.push({
>   id: assistantId,
>   role: "assistant",
>   content: "",
>   timestamp: new Date(),
> });
> await streamChat(content, history, (chunk) => {
>   const msg = conversation.messages.find((m) => m.id === assistantId);
>   if (msg) msg.content += chunk;
> });
> ```

### Environment Variable

```env
# frontend/.env
VITE_API_URL=http://localhost:5000
```

---

## Code Style & Conventions

- **TypeScript** everywhere — no `any` unless unavoidable
- Use `async/await` — no `.then()` chains
- Single-responsibility components — keep components under ~200 lines
- Name Vue components in PascalCase
- Name C# files/classes in PascalCase, variables in camelCase
- No login, no JWT, no authentication of any kind

---

## Do NOT

- Do not add authentication or authorization
- Do not use Minimal API in the .NET backend
- Do not use Options API in Vue components
- Do not hardcode API keys or secrets
- Do not use plain CSS files — use Tailwind utility classes
- Do not use `axios` — use native `fetch` for SSE streaming
- Do not pass full URL path to `AzureOpenAIClient` — use base URL only (e.g. `https://resource.openai.azure.com/`)
