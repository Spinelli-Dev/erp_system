// US16 — DTOs de Redefinição de Senha
namespace MaxiMassasAPI.DTOs.Request;

/// <summary>Passo 1 (painel): e-mail OU login do usuário, para receber o link de redefinição.</summary>
public class ForgotPasswordRequest
{
    /// <summary>E-mail cadastrado ou login do usuário.</summary>
    public string Email { get; set; } = string.Empty;
}

/// <summary>Passo 2 (painel): token recebido no link e a nova senha.</summary>
public class ResetPasswordRequest
{
    /// <summary>Token do link recebido por e-mail. Expira em 1 hora e é de uso único.</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>Nova senha (PoliticaSenha: 8+ caracteres, letras e números).</summary>
    public string NovaSenha { get; set; } = string.Empty;

    /// <summary>Confirmação da nova senha (deve ser idêntica a NovaSenha).</summary>
    public string ConfirmarSenha { get; set; } = string.Empty;
}

/// <summary>App, passo 1: e-mail do cliente para receber o código de 6 dígitos.</summary>
public class EsqueciSenhaAppRequest
{
    public string Email { get; set; } = string.Empty;
}

/// <summary>App, passo 2: e-mail, código recebido e a nova senha.</summary>
public class RedefinirSenhaAppRequest
{
    public string Email { get; set; } = string.Empty;
    public string Codigo { get; set; } = string.Empty;
    public string NovaSenha { get; set; } = string.Empty;
}
