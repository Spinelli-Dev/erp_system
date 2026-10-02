// Handler de autenticacao Basic Auth para CLIENTES do app (tabela Clientes, login por e-mail).
// Separado do BasicAuthHandler (usuarios internos) para que um cliente nunca acesse
// endpoints de gestao, e vice-versa. Usado apenas pelos endpoints /api/app.
using MaxiMassasAPI.Repositories;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;

namespace MaxiMassasAPI.Configurations;

public class ClienteAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "ClienteAuth";

    private readonly IClienteRepository _clienteRepository;

    public ClienteAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger, UrlEncoder encoder,
        IClienteRepository clienteRepository)
        : base(options, logger, encoder)
    { _clienteRepository = clienteRepository; }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey("Authorization"))
            return AuthenticateResult.Fail("Header Authorization ausente.");
        try
        {
            var authHeader = AuthenticationHeaderValue.Parse(Request.Headers["Authorization"]!);
            if (!authHeader.Scheme.Equals("Basic", StringComparison.OrdinalIgnoreCase))
                return AuthenticateResult.Fail("Scheme invalido. Use Basic.");

            var creds = Encoding.UTF8.GetString(Convert.FromBase64String(authHeader.Parameter ?? string.Empty));
            var sep = creds.IndexOf(':');
            if (sep < 0) return AuthenticateResult.Fail("Formato de credenciais invalido.");

            var email = creds[..sep];
            var senha = creds[(sep + 1)..];

            var cliente = await _clienteRepository.GetByEmailAsync(email);
            if (cliente?.SenhaHash is null || !BCrypt.Net.BCrypt.Verify(senha, cliente.SenhaHash))
                return AuthenticateResult.Fail("E-mail ou senha invalidos.");

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, cliente.Id.ToString()),
                new Claim(ClaimTypes.Email, cliente.Email!),
                new Claim(ClaimTypes.GivenName, cliente.Nome),
                new Claim(ClaimTypes.Role, "Cliente")
            };

            var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, SchemeName));
            return AuthenticateResult.Success(new AuthenticationTicket(principal, SchemeName));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Erro na autenticacao do cliente.");
            return AuthenticateResult.Fail("Erro interno na autenticacao.");
        }
    }

    // Sem o header WWW-Authenticate: ele faz o navegador abrir a janela nativa de login,
    // o que atrapalha o app rodando na web. O app trata o 401 sozinho.
    protected override Task HandleChallengeAsync(AuthenticationProperties properties)
    {
        Response.StatusCode = 401;
        return Task.CompletedTask;
    }
}
