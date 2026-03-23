namespace backend.Models;

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
    public List<ChatMessageDto> ConversationHistory { get; set; } = [];
}
