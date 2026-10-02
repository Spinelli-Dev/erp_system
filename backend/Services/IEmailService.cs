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
    /// <summary>Painel: e-mail com o link para criar uma nova senha (válido por 1 hora).</summary>
    Task EnviarLinkRedefinicaoAsync(string destinatario, string nome, string link);

    /// <summary>App: e-mail com o código de 6 dígitos para criar uma nova senha (válido por 15 minutos).</summary>
    Task EnviarCodigoRedefinicaoAsync(string destinatario, string nome, string codigo);

    /// <summary>Envia e-mail genérico.</summary>
    Task EnviarAsync(string destinatario, string assunto, string corpo);
}
