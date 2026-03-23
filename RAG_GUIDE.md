# RAG (Retrieval-Augmented Generation) — แนวทางการทำ

## RAG คืออะไร?

**RAG** คือเทคนิคที่ทำให้ AI "ค้นหาข้อมูลที่เกี่ยวข้อง" จากฐานข้อมูลของเราก่อน แล้วค่อยนำข้อมูลนั้นไปให้ model ใช้ตอบคำถาม

แทนที่จะถามตรงๆ ว่า "นโยบายบริษัทคืออะไร?" → model ไม่รู้  
RAG จะ **ค้นหาเอกสารที่เกี่ยวข้อง** ก่อน แล้วส่งไปให้ model พร้อม context → model ตอบได้แม่นยำ

---

## ภาพรวม Flow

```
[ผู้ใช้ถามคำถาม]
        │
        ▼
[1. Embed คำถาม → Vector]
        │
        ▼
[2. ค้นหาเอกสารที่ใกล้เคียงที่สุดจาก Vector DB]
        │
        ▼
[3. นำเอกสารที่เจอมาประกอบเป็น Prompt (Context Injection)]
        │
        ▼
[4. ส่ง Prompt ไปให้ Azure OpenAI]
        │
        ▼
[5. AI ตอบโดยอ้างอิงจากเอกสารที่ค้นเจอ]
        │
        ▼
[แสดงผลบนหน้าจอ + streaming เหมือนเดิม]
```

---

## 2 Phase ของ RAG

### Phase 1 — Indexing (ทำครั้งเดียวตอนเตรียมข้อมูล)

```
[เอกสาร / PDF / TXT / Markdown]
        │
        ▼
[Chunking — แบ่งเป็นก้อนย่อยๆ ~500 tokens]
        │
        ▼
[Embedding — แปลงแต่ละ chunk → Vector (array of float)]
        │  ใช้ Azure OpenAI Embedding model: text-embedding-ada-002
        ▼
[เก็บ Vector + ข้อความต้นฉบับลง Vector Database]
        │  เช่น Azure AI Search, Qdrant, pgvector, Chroma
        ▼
[Vector DB พร้อมใช้งาน]
```

### Phase 2 — Querying (ทำทุกครั้งที่ user ถาม)

```
[User ถาม: "วันหยุดบริษัทมีกี่วัน?"]
        │
        ▼
[Embed คำถาม → Vector]
        │  ใช้ Embedding model เดียวกับตอน Indexing
        ▼
[Similarity Search ใน Vector DB]
        │  ค้นหา top-K chunks ที่ใกล้เคียงที่สุด (cosine similarity)
        ▼
[ได้ Context กลับมา เช่น:]
        │  "พนักงานมีวันหยุดประจำปี 15 วัน ตามระเบียบปี 2024..."
        ▼
[สร้าง Prompt รวม Context + คำถาม]
        │
        │  System Prompt:
        │  "ตอบคำถามโดยอ้างอิงจากข้อมูลต่อไปนี้เท่านั้น:
        │   {context}"
        │
        │  User Message:
        │  "วันหยุดบริษัทมีกี่วัน?"
        ▼
[ส่งไปให้ Azure OpenAI → Streaming Response]
        ▼
[แสดงคำตอบบน ChatWindow]
```

---

## สิ่งที่ต้องเพิ่มในโปรเจกต์นี้

### บน Azure

| Service             | หน้าที่                             | ราคา (คร่าวๆ)       |
| ------------------- | ----------------------------------- | ------------------- |
| **Azure OpenAI**    | ใช้อยู่แล้ว — เพิ่ม Embedding model | ตาม token           |
| **Azure AI Search** | Vector Database ของ Azure (แนะนำ)   | ~$250/เดือน (Basic) |

> ทางเลือกอื่นที่ถูกกว่า: **Qdrant** (self-hosted), **pgvector** (PostgreSQL extension), **Chroma** (local)

### NuGet Packages ที่ต้องเพิ่ม (Backend)

```xml
<PackageReference Include="Azure.Search.Documents" Version="11.*" />
<!-- หรือถ้าใช้ Qdrant -->
<PackageReference Include="Qdrant.Client" Version="1.*" />
```

---

## โครงสร้างโค้ดที่ต้องเพิ่ม

```
backend/
├── Controllers/
│   ├── ChatController.cs       (มีอยู่แล้ว — แก้นิดหน่อย)
│   └── DocumentController.cs   (ใหม่ — สำหรับ upload เอกสาร)
├── Services/
│   ├── ChatService.cs          (มีอยู่แล้ว — เพิ่ม context injection)
│   ├── EmbeddingService.cs     (ใหม่ — แปลงข้อความ → Vector)
│   └── VectorSearchService.cs  (ใหม่ — ค้นหาใน Vector DB)
├── Models/
│   ├── ChatRequest.cs          (มีอยู่แล้ว)
│   ├── DocumentChunk.cs        (ใหม่ — โครงสร้างข้อมูลใน Vector DB)
│   └── SearchResult.cs         (ใหม่ — ผลลัพธ์จากการค้นหา)
└── Helpers/
    └── TextChunker.cs          (ใหม่ — แบ่งเอกสารเป็น chunk)
```

---

## ตัวอย่างโค้ดที่ต้องเปลี่ยน

### EmbeddingService.cs (ใหม่)

```csharp
public class EmbeddingService : IEmbeddingService
{
    private readonly AzureOpenAIClient _client;
    private readonly string _embeddingDeployment; // "text-embedding-ada-002"

    public async Task<float[]> GetEmbeddingAsync(string text)
    {
        var client = _client.GetEmbeddingClient(_embeddingDeployment);
        var result = await client.GenerateEmbeddingAsync(text);
        return result.Value.ToFloats().ToArray();
    }
}
```

### ChatService.cs (แก้ไข — เพิ่ม RAG)

```csharp
public async IAsyncEnumerable<string> StreamAsync(
    IEnumerable<ChatMessageDto> history,
    string newMessage)
{
    // [ใหม่] ค้นหา context ที่เกี่ยวข้องก่อน
    var relevantChunks = await _vectorSearch.SearchAsync(newMessage, topK: 3);
    var context = string.Join("\n\n", relevantChunks.Select(c => c.Text));

    var messages = new List<ChatMessage>();

    // [ใหม่] ใส่ System Prompt พร้อม Context
    if (!string.IsNullOrEmpty(context))
    {
        messages.Add(new SystemChatMessage(
            $"ตอบคำถามโดยอ้างอิงจากข้อมูลต่อไปนี้เท่านั้น:\n\n{context}" +
            "\n\nถ้าข้อมูลไม่เพียงพอให้ตอบตามความรู้ทั่วไป"));
    }

    // ส่วนที่เหลือเหมือนเดิม...
    foreach (var msg in history) { ... }
    messages.Add(new UserChatMessage(newMessage));

    await foreach (var update in chatClient.CompleteChatStreamingAsync(messages))
        foreach (var part in update.ContentUpdate)
            if (!string.IsNullOrEmpty(part.Text))
                yield return part.Text;
}
```

### DocumentController.cs (ใหม่ — Upload เอกสาร)

```csharp
[HttpPost("upload")]
public async Task<IActionResult> Upload(IFormFile file)
{
    var text = await ExtractText(file);           // อ่านข้อความจาก PDF/TXT
    var chunks = _chunker.Split(text, size: 500); // แบ่งเป็น chunk

    foreach (var chunk in chunks)
    {
        var vector = await _embedding.GetEmbeddingAsync(chunk);
        await _vectorSearch.IndexAsync(chunk, vector); // เก็บลง Vector DB
    }

    return Ok(new { message = $"Indexed {chunks.Count} chunks" });
}
```

---

## การเปลี่ยนแปลง Frontend

### เพิ่ม Upload หน้า (ถ้าต้องการ)

```
src/
├── components/
│   └── DocumentUpload.vue   (ใหม่ — drag & drop อัปโหลดเอกสาร)
├── views/
│   ├── ChatView.vue         (มีอยู่แล้ว)
│   └── DocumentView.vue     (ใหม่ — จัดการเอกสาร)
└── services/
    ├── api.ts               (มีอยู่แล้ว)
    └── documentApi.ts       (ใหม่ — upload document)
```

---

## ลำดับขั้นตอนการ Implement

```
Step 1: Deploy Embedding model บน Azure OpenAI
         └─ text-embedding-ada-002 หรือ text-embedding-3-small

Step 2: สร้าง Vector Database
         └─ สร้าง Azure AI Search resource (หรือ Qdrant local)

Step 3: สร้าง EmbeddingService + VectorSearchService

Step 4: สร้าง DocumentController (upload + indexing pipeline)

Step 5: แก้ ChatService ให้ค้นหา context ก่อนส่ง prompt

Step 6: (Optional) สร้างหน้า Upload เอกสารบน Frontend

Step 7: ทดสอบ end-to-end
```

---

## ข้อควรพิจารณา

| ประเด็น                   | รายละเอียด                                                                               |
| ------------------------- | ---------------------------------------------------------------------------------------- |
| **Chunk Size**            | ~500 tokens ต่อ chunk — ใหญ่เกินไปทำให้ context เยอะเกิน, เล็กเกินไปทำให้ context ขาดหาย |
| **Top-K**                 | ส่ง context 3-5 chunks ต่อคำถาม — มากเกินทำให้ prompt ยาวและแพง                          |
| **Embedding Consistency** | ต้องใช้ Embedding model เดิมทั้ง indexing และ querying                                   |
| **ค่าใช้จ่าย**            | Embedding ถูกมาก (~$0.0001/1K tokens) แต่ Vector DB อาจแพง                               |
| **Re-ranking**            | ถ้าต้องการความแม่นยำสูง ใช้ Cross-encoder re-rank ผลลัพธ์อีกครั้ง                        |
