// Handler de autenticacao Basic Auth.
// Fluxo: Header -> Decode base64 -> Verificar BCrypt -> Claims -> AuthenticateResult.
using MaxiMassasAPI.Repositories;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;

namespace MaxiMassasAPI.Configurations;

public class BasicAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly IUsuarioRepository _usuarioRepository;

    public BasicAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger, UrlEncoder encoder,
        IUsuarioRepository usuarioRepository)
        : base(options, logger, encoder)
    { _usuarioRepository = usuarioRepository; }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey("Authorization"))
            return AuthenticateResult.Fail("Header Authorization ausente.");
        try
        {
            var authHeader = AuthenticationHeaderValue.Parse(Request.Headers["Authorization"]!);
            if (!authHeader.Scheme.Equals("Basic", StringComparison.OrdinalIgnoreCase))
                return AuthenticateResult.Fail("Scheme invalido. Use Basic.");

            var credBytes = Convert.FromBase64String(authHeader.Parameter ?? string.Empty);
            var creds = Encoding.UTF8.GetString(credBytes);
            var sep = creds.IndexOf(':');
            if (sep < 0) return AuthenticateResult.Fail("Formato de credenciais invalido.");

            var login = creds[..sep];
            var senha = creds[(sep + 1)..];

            var usuario = await _usuarioRepository.GetByLoginAsync(login);
            if (usuario is null || !BCrypt.Net.BCrypt.Verify(senha, usuario.Senha))
                return AuthenticateResult.Fail("Login ou senha invalidos.");

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
                new Claim(ClaimTypes.Name, usuario.Login),
                new Claim(ClaimTypes.GivenName, usuario.Nome),
                new Claim(ClaimTypes.Role, usuario.Tipo.ToString())
            };

            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            return AuthenticateResult.Success(new AuthenticationTicket(principal, Scheme.Name));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Erro na autenticacao Basic Auth.");
            return AuthenticateResult.Fail("Erro interno na autenticacao.");
        }
    }

    protected override Task HandleChallengeAsync(AuthenticationProperties properties)
    {
        Response.StatusCode = 401;
        Response.Headers["WWW-Authenticate"] = "Basic realm=\"MaxiMassasAPI\", charset=\"UTF-8\"";
        return Task.CompletedTask;
    }
}