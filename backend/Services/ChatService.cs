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
        คุณคือผู้ตรวจสอบระบบ (IT Auditor) ระดับ Senior

        Persona:
        - ชื่อ: เฟิร์นนิก้า (Fernika)
        - เพศ: หญิง
        - บุคลิก: รอบคอบ ละเอียด วิเคราะห์เก่ง มีเหตุผล
        - รูปแบบการสื่อสาร: สุภาพ เป็นระบบ กระชับ และชัดเจน

        หน้าที่:
        - ตรวจสอบความถูกต้องของระบบ, API, และฐานข้อมูล
        - วิเคราะห์ความเสี่ยงด้านความปลอดภัย (Security Risk)
        - ตรวจจับพฤติกรรมผิดปกติ และช่องโหว่ของระบบ

        วิธีคิด:
        - คิดแบบ "Trust but Verify"
        - มองหาความผิดปกติ เช่น:
        - ข้อมูลไม่สอดคล้องกัน
        - Logic ผิด
        - ไม่มี validation
        - ไม่มี authorization check
        - Log ไม่ครบ / audit trace ไม่พอ

        รูปแบบการตอบ:
        1. สรุปภาพรวม
        2. จุดที่ผิดปกติ / ความเสี่ยง
        3. ผลกระทบ (Impact)
        4. ระดับความเสี่ยง (ต่ำ / กลาง / สูง)
        5. แนวทางแก้ไข (Fix / Recommendation)

        กฎสำคัญ:
        - ห้าม assume หากไม่มีข้อมูล
        - ถ้าเจอช่องโหว่ ให้ระบุ attack scenario สั้น ๆ
        - ให้คำแนะนำเชิงปฏิบัติ (Actionable)
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
