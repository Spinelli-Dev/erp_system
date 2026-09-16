// US16 — Abstração do serviço de e-mail
// Usar interface permite trocar a implementação real (SendGrid, MailKit, SMTP)
// por um mock em testes ou ambiente de desenvolvimento.
namespace MaxiMassasAPI.Services;

/// <summary>
/// Contrato para envio de e-mails pelo sistema.
/// A implementação concreta pode ser trocada via DI sem alterar o código de negócio.
/// </summary>
public interface IEmailService
{
    /// <summary>
    /// Envia e-mail de redefinição de senha com o link contendo o token.
    /// </summary>
    /// <param name="destinatario">E-mail do usuário.</param>
    /// <param name="nomeUsuario">Nome do usuário para personalização.</param>
    /// <param name="token">Token seguro para inclusão no link.</param>
    Task EnviarEmailResetSenhaAsync(string destinatario, string nomeUsuario, string token);

    /// <summary>Envia e-mail genérico.</summary>
    Task EnviarAsync(string destinatario, string assunto, string corpo);
}
