// US16 — Redefinição de Senha
// Armazena tokens temporários e de uso único para reset de senha.
// Token expira em 1 hora e é invalidado após uso.
namespace MaxiMassasAPI.Models;

public class PasswordResetToken
{
    public int Id { get; set; }

    /// <summary>E-mail do usuário que solicitou a redefinição.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>Token único gerado (GUID ou hash seguro).</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>Data/hora de expiração do token.</summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>Indica se o token já foi utilizado (uso único).</summary>
    public bool Usado { get; set; } = false;

    /// <summary>Data de criação para auditoria.</summary>
    public DateTime CriadoEm { get; set; } = DateTime.Now;
}
