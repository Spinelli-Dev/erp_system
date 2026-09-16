// AuthController: Autenticação + US16 Redefinição de Senha
using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Repositories;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IUsuarioRepository _repo;
    private readonly IAuthService _authService;

    public AuthController(IUsuarioRepository repo, IAuthService authService)
    {
        _repo = repo;
        _authService = authService;
    }

    /// <summary>Retorna os dados do usuario autenticado via Basic Auth.</summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> Me()
    {
        var login = User.Identity?.Name;
        if (string.IsNullOrEmpty(login)) return Unauthorized(ApiResponse.Fail("Nao autenticado."));
        var usuario = await _repo.GetByLoginAsync(login);
        if (usuario is null) return Unauthorized(ApiResponse.Fail("Usuario nao encontrado."));
        var response = new UsuarioResponse { Id = usuario.Id, Nome = usuario.Nome, Login = usuario.Login, Tipo = usuario.Tipo };
        return Ok(ApiResponse<UsuarioResponse>.Ok(response, $"Bem-vindo, {usuario.Nome}!"));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/forgot-password
    // US16 — Passo 1: Solicitar redefinição de senha
    // Usuário informa o e-mail (= Login no sistema) e recebe um link por e-mail.
    // SEGURANÇA: sempre retorna 200 para não revelar se o e-mail existe no sistema.
    // -------------------------------------------------------------------------
    /// <summary>
    /// Solicita redefinição de senha. Envia link com token para o e-mail informado.
    /// O token expira em 1 hora e pode ser usado apenas uma vez.
    /// </summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email))
            return BadRequest(ApiResponse.Fail("O e-mail é obrigatório."));

        // Sempre retorna 200 — não vaza informação sobre existência do e-mail
        await _authService.SolicitarResetSenhaAsync(request.Email.Trim().ToLower());

        return Ok(ApiResponse.Ok(
            "Se o e-mail estiver cadastrado, você receberá as instruções de redefinição em breve."));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/reset-password
    // US16 — Passo 2: Redefinir senha com o token recebido por e-mail
    // Token deve ser válido (não expirado e não utilizado anteriormente).
    // -------------------------------------------------------------------------
    /// <summary>
    /// Redefine a senha usando o token recebido por e-mail.
    /// O token é invalidado após o uso (uso único).
    /// </summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
            return BadRequest(ApiResponse.Fail("O token é obrigatório."));

        if (string.IsNullOrWhiteSpace(request.NovaSenha))
            return BadRequest(ApiResponse.Fail("A nova senha é obrigatória."));

        // InvalidOperationException carrega mensagem de negócio para o usuário
        var sucesso = await _authService.RedefinirSenhaAsync(request);

        return Ok(ApiResponse.Ok("Senha redefinida com sucesso. Você já pode fazer login com a nova senha."));
    }
}
