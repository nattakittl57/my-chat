using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Cors;
using backend.Interfaces;
using backend.Models;
using System.Text;

namespace backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[EnableCors("AllowFrontend")]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;

    public ChatController(IChatService chatService)
    {
        _chatService = chatService;
    }

    // test git
    [HttpPost]
    public async Task SendMessage([FromBody] ChatRequest request, CancellationToken cancellationToken)
    {
        Response.ContentType = "text/event-stream";
        Response.Headers.CacheControl = "no-cache";
        Response.Headers.Connection = "keep-alive";

        await foreach (var chunk in _chatService.StreamAsync(request.ConversationHistory, request.Message).WithCancellation(cancellationToken))
        {
            var data = $"data: {chunk}\n\n";
            await Response.Body.WriteAsync(Encoding.UTF8.GetBytes(data), cancellationToken);
            await Response.Body.FlushAsync(cancellationToken);
        }

        await Response.Body.WriteAsync(Encoding.UTF8.GetBytes("data: [DONE]\n\n"), cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);
    }
}
