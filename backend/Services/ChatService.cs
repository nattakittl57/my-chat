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

    public async IAsyncEnumerable<string> StreamAsync(IEnumerable<ChatMessageDto> history, string newMessage)
    {
        var chatClient = _client.GetChatClient(_deployment);

        var messages = new List<ChatMessage>();

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
