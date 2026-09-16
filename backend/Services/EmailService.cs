// US16 — Implementação do Serviço de E-mail
// Usa MailKit para envio real via SMTP.
// Em ambiente de desenvolvimento (EmailSettings:MockMode = true), apenas loga o e-mail
// sem enviá-lo de verdade — ideal para testes sem conta SMTP configurada.
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Serviço de envio de e-mail usando MailKit.
/// Configuração em appsettings.json na seção "EmailSettings".
///
/// Para desenvolvimento: defina "MockMode": true e o e-mail é apenas logado.
/// Para produção: configure Host, Port, Username, Password e MockMode: false.
/// </summary>
public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    // Lê as configurações uma vez no construtor
    private readonly string _host;
    private readonly int _port;
    private readonly string _username;
    private readonly string _password;
    private readonly string _remetente;
    private readonly string _nomeRemetente;
    private readonly bool _mockMode;
    private readonly string _urlBase;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;

        var section = config.GetSection("EmailSettings");
        _host = section["Host"] ?? "smtp.mailtrap.io";
        _port = section.GetValue<int>("Port", 587);
        _username = section["Username"] ?? "";
        _password = section["Password"] ?? "";
        _remetente = section["Remetente"] ?? "noreply@maximassas.com.br";
        _nomeRemetente = section["NomeRemetente"] ?? "MaxiMassas Sistema";
        _mockMode = section.GetValue<bool>("MockMode", true); // padrão: mock ativo
        _urlBase = section["UrlBase"] ?? "http://localhost:5000";
    }

    /// <inheritdoc/>
    public async Task EnviarEmailResetSenhaAsync(string destinatario, string nomeUsuario, string token)
    {
        // Monta o link que o usuário receberá no e-mail
        // Em produção, este link aponta para o front-end que chama POST /auth/reset-password
        var link = $"{_urlBase}/redefinir-senha?token={Uri.EscapeDataString(token)}";

        var assunto = "MaxiMassas — Redefinição de Senha";
        var corpo = $@"
            <h2>Olá, {nomeUsuario}!</h2>
            <p>Recebemos uma solicitação de redefinição de senha para sua conta na <strong>MaxiMassas</strong>.</p>
            <p>Clique no link abaixo para criar uma nova senha. 
               <strong>Este link expira em 1 hora</strong> e pode ser usado apenas uma vez.</p>
            <p><a href='{link}' style='background:#e67e22;color:white;padding:10px 20px;text-decoration:none;border-radius:5px;'>
               Redefinir minha senha
            </a></p>
            <p>Se você não solicitou a redefinição, ignore este e-mail.</p>
            <hr/>
            <small>MaxiMassas — Sistema de Gestão</small>
        ";

        await EnviarAsync(destinatario, assunto, corpo);
    }

    /// <inheritdoc/>
    public async Task EnviarAsync(string destinatario, string assunto, string corpo)
    {
        // MODO MOCK: apenas loga — útil em dev/staging sem SMTP real configurado
        if (_mockMode)
        {
            _logger.LogInformation(
                "[EmailService:MOCK] Para={Para} | Assunto={Assunto} | Corpo={Corpo}",
                destinatario, assunto, corpo);
            return; // Retorna sem enviar
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
            throw; // Relança para o controller tratar e retornar mensagem adequada
        }
    }
}
