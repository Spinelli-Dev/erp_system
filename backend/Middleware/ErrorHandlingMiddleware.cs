// Middleware global de tratamento de erros. Captura excecoes e retorna JSON padronizado.
using MaxiMassasAPI.DTOs.Common;
using System.Net;
using System.Text.Json;

namespace MaxiMassasAPI.Middleware;

public class ErrorHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ErrorHandlingMiddleware> _logger;

    public ErrorHandlingMiddleware(RequestDelegate next, ILogger<ErrorHandlingMiddleware> logger)
    { _next = next; _logger = logger; }

    public async Task InvokeAsync(HttpContext context)
    {
        try { await _next(context); }
        catch (KeyNotFoundException ex) { await Handle(context, ex, HttpStatusCode.NotFound, ex.Message); }
        catch (InvalidOperationException ex) { await Handle(context, ex, HttpStatusCode.BadRequest, ex.Message); }
        catch (UnauthorizedAccessException ex) { await Handle(context, ex, HttpStatusCode.Forbidden, "Acesso negado."); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro interno: {Message}", ex.Message);
            await Handle(context, ex, HttpStatusCode.InternalServerError, "Ocorreu um erro interno. Tente novamente.");
        }
    }

    private static async Task Handle(HttpContext ctx, Exception ex, HttpStatusCode code, string msg)
    {
        ctx.Response.ContentType = "application/json";
        ctx.Response.StatusCode = (int)code;
        var resp = ApiResponse.Fail(msg, new List<string> { ex.GetType().Name });
        await ctx.Response.WriteAsync(JsonSerializer.Serialize(resp,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }));
    }
}