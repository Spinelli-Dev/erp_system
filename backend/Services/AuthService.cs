// US16 — Service de Autenticação / Redefinição de Senha
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Contrato para operações de autenticação avançada.
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Passo 1: gera token de reset e envia por e-mail.
    /// Retorna true se o e-mail foi encontrado (mesmo que o envio falhe gracefully).
    /// SEGURANÇA: sempre retorna mesma mensagem para não vazar se e-mail existe ou não.
    /// </summary>
    Task<bool> SolicitarResetSenhaAsync(string email);

    /// <summary>
    /// Passo 2: valida o token e redefine a senha do usuário.
    /// </summary>
    Task<bool> RedefinirSenhaAsync(ResetPasswordRequest request);
}

/// <summary>
/// Implementação do fluxo de redefinição de senha em dois passos:
///   1. Usuário informa e-mail → sistema gera token e envia link
///   2. Usuário clica no link → informa nova senha → sistema valida token e salva
///
/// SEGURANÇA:
///   - Token gerado com Guid.NewGuid() + timestamp (alta entropia, 128 bits)
///   - Expiração de 1 hora
///   - Uso único: invalidado após a redefinição
///   - Bcrypt para hash da nova senha
/// </summary>
public class AuthService : IAuthService
{
    private readonly AppDbContext _context;
    private readonly IUsuarioRepository _usuarioRepo;
    private readonly IEmailService _emailService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        AppDbContext context,
        IUsuarioRepository usuarioRepo,
        IEmailService emailService,
        ILogger<AuthService> logger)
    {
        _context = context;
        _usuarioRepo = usuarioRepo;
        _emailService = emailService;
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task<bool> SolicitarResetSenhaAsync(string email)
    {
        // Busca usuário pelo e-mail (campo Login é usado como e-mail no sistema)
        var usuario = await _usuarioRepo.GetByLoginAsync(email);

        // SEGURANÇA: não revelamos se o e-mail existe ou não (evita user enumeration)
        // Apenas logamos internamente para diagnóstico
        if (usuario is null)
        {
            _logger.LogWarning("[ResetSenha] Solicitação para e-mail não cadastrado: {Email}", email);
            return true; // Retorna true de qualquer forma (resposta genérica ao cliente)
        }

        // Invalida tokens anteriores não utilizados para o mesmo e-mail
        // (evita acúmulo de tokens válidos no banco)
        var tokensAntigos = await _context.PasswordResetTokens
            .Where(t => t.Email == email && !t.Usado && t.ExpiresAt > DateTime.Now)
            .ToListAsync();
        tokensAntigos.ForEach(t => t.Usado = true);

        // Gera token único e seguro (GUID v4 = 122 bits de aleatoriedade)
        var token = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N"); // 64 chars hex

        var resetToken = new PasswordResetToken
        {
            Email = email,
            Token = token,
            ExpiresAt = DateTime.Now.AddHours(1), // expira em 1 hora
            Usado = false,
            CriadoEm = DateTime.Now
        };

        await _context.PasswordResetTokens.AddAsync(resetToken);
        await _context.SaveChangesAsync();

        // Envia e-mail com o link (implementação pode ser mock em dev)
        try
        {
            await _emailService.EnviarEmailResetSenhaAsync(email, usuario.Nome, token);
        }
        catch (Exception ex)
        {
            // Não deixa falha de e-mail derrubar o fluxo — token já foi criado
            _logger.LogError(ex, "[ResetSenha] Falha no envio de e-mail para {Email}", email);
        }

        _logger.LogInformation("[ResetSenha] Token gerado para {Email}, expira às {Expira}",
            email, resetToken.ExpiresAt);

        return true;
    }

    /// <inheritdoc/>
    public async Task<bool> RedefinirSenhaAsync(ResetPasswordRequest request)
    {
        // Validação básica antes de acessar o banco
        if (request.NovaSenha != request.ConfirmarSenha)
            throw new InvalidOperationException("A nova senha e a confirmação não coincidem.");

        if (request.NovaSenha.Length < 6)
            throw new InvalidOperationException("A senha deve ter no mínimo 6 caracteres.");

        // Busca token válido no banco: deve existir, não ter sido usado e não ter expirado
        var resetToken = await _context.PasswordResetTokens
            .FirstOrDefaultAsync(t =>
                t.Token == request.Token &&
                !t.Usado &&
                t.ExpiresAt > DateTime.Now);

        if (resetToken is null)
            throw new InvalidOperationException(
                "Token inválido, já utilizado ou expirado. Solicite uma nova redefinição.");

        // Busca o usuário vinculado ao e-mail do token
        var usuario = await _usuarioRepo.GetByLoginAsync(resetToken.Email);
        if (usuario is null)
            throw new InvalidOperationException("Usuário associado ao token não encontrado.");

        // Atualiza a senha com hash BCrypt (mesmo padrão do sistema existente)
        usuario.Senha = BCrypt.Net.BCrypt.HashPassword(request.NovaSenha);

        // Marca o token como usado (não pode ser reutilizado — uso único)
        resetToken.Usado = true;

        await _context.SaveChangesAsync();

        _logger.LogInformation("[ResetSenha] Senha redefinida com sucesso para {Email}", resetToken.Email);

        return true;
    }
}
