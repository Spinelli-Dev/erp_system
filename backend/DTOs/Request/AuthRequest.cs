// US16 — DTOs de Redefinição de Senha
namespace MaxiMassasAPI.DTOs.Request;

/// <summary>
/// Passo 1: usuário informa o e-mail para receber o link de redefinição.
/// </summary>
public class ForgotPasswordRequest
{
    /// <summary>E-mail cadastrado no sistema.</summary>
    public string Email { get; set; } = string.Empty;
}

/// <summary>
/// Passo 2: usuário informa o token recebido por e-mail e a nova senha.
/// </summary>
public class ResetPasswordRequest
{
    /// <summary>Token único recebido no e-mail. Expira em 1 hora e é de uso único.</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>Nova senha desejada (mínimo 6 caracteres).</summary>
    public string NovaSenha { get; set; } = string.Empty;

    /// <summary>Confirmação da nova senha (deve ser idêntica a NovaSenha).</summary>
    public string ConfirmarSenha { get; set; } = string.Empty;
}
