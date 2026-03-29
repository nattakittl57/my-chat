using Azure.AI.OpenAI;
using OpenAI.Chat;
using backend.Interfaces;
using backend.Models;

namespace backend.Services;

public class ChatService : IChatService
{
    private readonly AzureOpenAIClient _client;
    private readonly string _deployment;

    public ChatService(AzureOpenAIClient client, IConfiguration config)
    {
        _client = client;
        _deployment = config["AzureOpenAI:DeploymentName"]!;
    }

    private const string SystemPrompt =
        """
        คุณคือผู้ตรวจสอบบัญชี (Auditor) มืออาชีพ ที่มีความเชี่ยวชาญด้านการตรวจสอบทางการเงิน การควบคุมภายใน การประเมินความเสี่ยง และการปฏิบัติตามกฎหมาย/มาตรฐานบัญชี
        
        ชื่อ เฟิร์นนิก้า (Fernika)
        
        บริบท:
        - มีหน้าที่ตรวจสอบข้อมูลทางการเงิน
        - วิเคราะห์ความผิดปกติ
        - ประเมินความเสี่ยง และตรวจสอบการปฏิบัติตามข้อกำหนด

        คำสั่ง:
        - ให้ตอบในรูปแบบโครงสร้างเสมอ:
          1. สรุป
          2. ประเด็นที่พบ (Findings)
          3. ระดับความเสี่ยง (ต่ำ / กลาง / สูง)
          4. ข้อเสนอแนะ
        - ใช้ภาษาทางการ กระชับ ชัดเจน
        - หากข้อมูลไม่ครบ ให้ระบุสมมติฐาน
        - สามารถถามคำถามเพิ่มเติมได้
        - หลีกเลี่ยงการคาดเดาโดยไม่มีข้อมูลรองรับ

        โทน:
        - เป็นกลาง เป็นมืออาชีพ
        - เน้นข้อเท็จจริง
        """;

    public async IAsyncEnumerable<string> StreamAsync(IEnumerable<ChatMessageDto> history, string newMessage)
    {
        var chatClient = _client.GetChatClient(_deployment);

        var messages = new List<ChatMessage>
        {
            new SystemChatMessage(SystemPrompt)
        };

        foreach (var msg in history)
        {
            if (msg.Role == "user")
                messages.Add(new UserChatMessage(msg.Content));
            else if (msg.Role == "assistant")
                messages.Add(new AssistantChatMessage(msg.Content));
        }

        messages.Add(new UserChatMessage(newMessage));

        await foreach (var update in chatClient.CompleteChatStreamingAsync(messages))
        {
            foreach (var part in update.ContentUpdate)
            {
                if (!string.IsNullOrEmpty(part.Text))
                    yield return part.Text;
            }
        }
    }
}
