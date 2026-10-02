// US16 — Implementação do Serviço de E-mail
// Usa MailKit para envio real via SMTP.
// Em ambiente de desenvolvimento (EmailSettings:MockMode = true), não envia de verdade:
// registra no log e grava cada e-mail como .html na pasta EmailsTeste (dá para abrir e clicar no link).
using System.Net;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Serviço de envio de e-mail usando MailKit.
/// Configuração em appsettings.json na seção "EmailSettings".
///
/// Para desenvolvimento: defina "MockMode": true e o e-mail é apenas registrado.
/// Para produção: configure Host, Port, Username, Password e MockMode: false.
/// </summary>
public class EmailService : IEmailService
{
    private readonly ILogger<EmailService> _logger;
    private readonly string _host;
    private readonly int _port;
    private readonly string _username;
    private readonly string _password;
    private readonly string _remetente;
    private readonly string _nomeRemetente;
    private readonly bool _mockMode;
    private readonly string _pastaTeste;

    public EmailService(IConfiguration config, ILogger<EmailService> logger, IWebHostEnvironment ambiente)
    {
        _logger = logger;

        var section = config.GetSection("EmailSettings");
        _host = section["Host"] ?? "smtp.mailtrap.io";
        _port = section.GetValue<int>("Port", 587);
        _username = section["Username"] ?? "";
        _password = section["Password"] ?? "";
        _remetente = section["Remetente"] ?? "noreply@maximassas.com.br";
        _nomeRemetente = section["NomeRemetente"] ?? "MaxiMassas Sistema";
        _mockMode = section.GetValue<bool>("MockMode", true); // padrão: mock ativo
        _pastaTeste = Path.Combine(ambiente.ContentRootPath, "EmailsTeste");
    }

    public Task EnviarLinkRedefinicaoAsync(string destinatario, string nome, string link)
        => EnviarAsync(destinatario, "Maxi Massas — Criar uma nova senha", Modelo(nome, $@"
            <p>Recebemos um pedido para criar uma nova senha de acesso ao <strong>Sistema de Gestão Maxi Massas</strong>.</p>
            <p style=""text-align:center;margin:28px 0;"">
                <a href=""{WebUtility.HtmlEncode(link)}"" style=""background:#9A1006;color:#fff;padding:12px 28px;border-radius:8px;text-decoration:none;font-weight:600;"">Criar nova senha</a>
            </p>
            <p>O link vale por <strong>1 hora</strong> e só pode ser usado uma vez.</p>
            <p style=""color:#6B7280;font-size:13px;"">Se o botão não abrir, copie este endereço no navegador:<br>{WebUtility.HtmlEncode(link)}</p>"));

    public Task EnviarCodigoRedefinicaoAsync(string destinatario, string nome, string codigo)
        => EnviarAsync(destinatario, $"Maxi Massas — Seu código: {codigo}", Modelo(nome, $@"
            <p>Use este código no app <strong>Maxi Massas</strong> para criar uma nova senha:</p>
            <p style=""text-align:center;margin:28px 0;font-size:34px;letter-spacing:10px;font-weight:700;color:#9A1006;"">{codigo}</p>
            <p>O código vale por <strong>15 minutos</strong>. Não compartilhe com ninguém — a Maxi Massas nunca pede esse código.</p>"));

    /// <summary>Moldura comum dos e-mails (cores da marca).</summary>
    private static string Modelo(string nome, string conteudo) => $@"
        <div style=""font-family:Arial,Helvetica,sans-serif;max-width:520px;margin:0 auto;border:1px solid #EEEFF1;border-radius:12px;overflow:hidden;"">
            <div style=""background:#9A1006;color:#fff;padding:18px 24px;font-size:20px;font-weight:700;"">Maxi Massas</div>
            <div style=""padding:24px;color:#111827;font-size:15px;line-height:1.5;"">
                <p>Olá, {WebUtility.HtmlEncode(nome)}!</p>
                {conteudo}
                <p style=""color:#6B7280;font-size:13px;margin-top:24px;"">Se você não pediu isso, ignore este e-mail: sua senha continua a mesma.</p>
            </div>
            <div style=""background:#F9F9FA;color:#9CA3AC;padding:12px 24px;font-size:12px;"">Maxi Massas Itápolis</div>
        </div>";

    /// <inheritdoc/>
    public async Task EnviarAsync(string destinatario, string assunto, string corpo)
    {
        // MODO MOCK: não envia — registra no log e grava o e-mail em EmailsTeste/*.html
        if (_mockMode)
        {
            Directory.CreateDirectory(_pastaTeste);
            var arquivo = Path.Combine(_pastaTeste,
                $"{DateTime.Now:yyyyMMdd-HHmmss}-{string.Concat(destinatario.Split(Path.GetInvalidFileNameChars()))}.html");
            await File.WriteAllTextAsync(arquivo,
                $"<!doctype html><meta charset=\"utf-8\"><title>{WebUtility.HtmlEncode(assunto)}</title>" +
                $"<p style=\"font-family:Arial;color:#6B7280\">[MODO TESTE] Para: {WebUtility.HtmlEncode(destinatario)} — Assunto: {WebUtility.HtmlEncode(assunto)}</p>{corpo}");
            _logger.LogInformation("[EmailService:MOCK] Para={Para} | Assunto={Assunto} | Gravado em {Arquivo}",
                destinatario, assunto, arquivo);
            return;
        }

        // MODO REAL: envia via SMTP usando MailKit
        try
        {
            var mensagem = new MimeMessage();
            mensagem.From.Add(new MailboxAddress(_nomeRemetente, _remetente));
            mensagem.To.Add(MailboxAddress.Parse(destinatario));
            mensagem.Subject = assunto;

            // Envia como HTML para renderizar o botão e formatação
            mensagem.Body = new TextPart("html") { Text = corpo };

            using var client = new SmtpClient();
            await client.ConnectAsync(_host, _port, SecureSocketOptions.StartTls);
            await client.AuthenticateAsync(_username, _password);
            await client.SendAsync(mensagem);
            await client.DisconnectAsync(true);

            _logger.LogInformation("[EmailService] E-mail enviado para {Para}, assunto: {Assunto}", destinatario, assunto);
        }
        catch (Exception ex)
        {
            // Log do erro sem travar o fluxo principal (falha de e-mail não deve derrubar a API)
            _logger.LogError(ex, "[EmailService] Falha ao enviar e-mail para {Para}", destinatario);
            throw; // Relança para o chamador tratar
        }
    }
}
