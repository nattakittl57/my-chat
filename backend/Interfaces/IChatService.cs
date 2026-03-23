using backend.Models;

namespace backend.Interfaces;

public interface IChatService
{
    IAsyncEnumerable<string> StreamAsync(IEnumerable<ChatMessageDto> history, string newMessage);
}
