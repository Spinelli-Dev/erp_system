// Autenticação do painel web (páginas Razor) e a escolha de esquema da API.
//
// - Painel: login em Pages/Login cria um cookie de sessão (HttpOnly, SameSite=Strict).
// - API (/api): aceita Basic Auth (Swagger, integrações, painel antigo) OU o cookie do painel,
//   para os scripts das páginas Razor chamarem a API sem guardar senha no navegador.
//   Quem decide é o esquema "Padrao": com header "Authorization: Basic ..." usa o BasicAuth;
//   sem ele, usa o cookie.
// - App do cliente (/api/app): continua no esquema próprio ClienteAuth (ver AppController).
using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace MaxiMassasAPI.Configurations;

public static class PainelAuth
{
    /// <summary>Cookie de sessão do painel.</summary>
    public const string Scheme = "Painel";

    /// <summary>Política das páginas Razor: só o cookie do painel vale.</summary>
    public const string Policy = "Painel";

    /// <summary>Esquema padrão da API: escolhe entre BasicAuth e o cookie do painel.</summary>
    public const string SchemePadrao = "Padrao";

    public const string BasicScheme = "BasicAuth";

    /// <summary>Claim com a versão da foto (ticks); vazia = sem foto. O menu monta a URL da imagem com ela.</summary>
    public const string ClaimFoto = "maximassas:foto";

    /// <summary>Mesmos claims do BasicAuthHandler: os controllers leem Id, login, nome e perfil daqui.</summary>
    public static ClaimsPrincipal CriarPrincipal(Usuario usuario, string scheme)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new Claim(ClaimTypes.Name, usuario.Login),
            new Claim(ClaimTypes.GivenName, usuario.Nome),
            new Claim(ClaimTypes.Role, usuario.Tipo.ToString()),
            new Claim(ClaimFoto, VersaoFoto(usuario.FotoAtualizadaEm))
        };
        return new ClaimsPrincipal(new ClaimsIdentity(claims, scheme));
    }

    private static string VersaoFoto(DateTime? atualizadaEm) => atualizadaEm?.Ticks.ToString() ?? string.Empty;

    /// <summary>
    /// A cada requisição do painel: usuário excluído ou desativado perde a sessão na hora; e se o nome,
    /// o perfil ou a foto mudaram (pelo administrador ou em "Meu perfil"), o cookie é atualizado — o menu
    /// e as permissões refletem a mudança sem precisar sair e entrar de novo. (Poucos usuários: uma
    /// consulta simples por página não pesa.)
    /// </summary>
    private static async Task ValidarSessaoAsync(CookieValidatePrincipalContext ctx)
    {
        if (!int.TryParse(ctx.Principal?.FindFirstValue(ClaimTypes.NameIdentifier), out var id))
        {
            ctx.RejectPrincipal();
            return;
        }

        var db = ctx.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
        // Só as colunas usadas (a foto em si não é carregada).
        var atual = await db.Usuarios.AsNoTracking()
            .Where(u => u.Id == id)
            .Select(u => new Usuario { Id = u.Id, Login = u.Login, Nome = u.Nome, Tipo = u.Tipo, Ativo = u.Ativo, FotoAtualizadaEm = u.FotoAtualizadaEm })
            .FirstOrDefaultAsync();

        if (atual is null || !atual.Ativo)
        {
            ctx.RejectPrincipal();
            await ctx.HttpContext.SignOutAsync(Scheme);
            return;
        }

        var p = ctx.Principal!;
        var mudou = p.FindFirstValue(ClaimTypes.GivenName) != atual.Nome
                    || p.FindFirstValue(ClaimTypes.Role) != atual.Tipo.ToString()
                    || p.FindFirstValue(ClaimFoto) != VersaoFoto(atual.FotoAtualizadaEm);
        if (mudou)
        {
            ctx.ReplacePrincipal(CriarPrincipal(atual, Scheme));
            ctx.ShouldRenew = true;
        }
    }

    public static IServiceCollection AddPainelAuth(this IServiceCollection services)
    {
        services.AddAuthentication(SchemePadrao)
            .AddPolicyScheme(SchemePadrao, "Basic (API) ou cookie (painel)", o =>
            {
                o.ForwardDefaultSelector = ctx =>
                    ctx.Request.Headers.Authorization.ToString().StartsWith("Basic ", StringComparison.OrdinalIgnoreCase)
                        ? BasicScheme
                        : Scheme;
            })
            .AddScheme<AuthenticationSchemeOptions, BasicAuthHandler>(BasicScheme, null)
            // Clientes do app (Flutter) — usado só pelos endpoints /api/app
            .AddScheme<AuthenticationSchemeOptions, ClienteAuthHandler>(ClienteAuthHandler.SchemeName, null)
            .AddCookie(Scheme, o =>
            {
                o.LoginPath = "/Login";
                o.LogoutPath = "/Logout";
                o.AccessDeniedPath = "/Login";
                o.Cookie.Name = "MaxiMassas.Painel";
                o.Cookie.HttpOnly = true;
                // Strict: o navegador nunca manda o cookie em requisições vindas de outro site.
                o.Cookie.SameSite = SameSiteMode.Strict;
                o.Cookie.SecurePolicy = CookieSecurePolicy.Always;
                o.ExpireTimeSpan = TimeSpan.FromHours(8);
                o.SlidingExpiration = true;
                // Na API, sem sessão é 401/403 (o script trata); só as páginas redirecionam para o login.
                o.Events.OnRedirectToLogin = ctx => ResponderOuRedirecionar(ctx, StatusCodes.Status401Unauthorized);
                o.Events.OnRedirectToAccessDenied = ctx => ResponderOuRedirecionar(ctx, StatusCodes.Status403Forbidden);
                o.Events.OnValidatePrincipal = ValidarSessaoAsync;
            });

        services.AddAuthorization(o =>
            o.AddPolicy(Policy, p => p.AddAuthenticationSchemes(Scheme).RequireAuthenticatedUser()));

        return services;
    }

    private static Task ResponderOuRedirecionar(
        RedirectContext<CookieAuthenticationOptions> ctx, int status)
    {
        if (ctx.Request.Path.StartsWithSegments("/api"))
            ctx.Response.StatusCode = status;
        else
            ctx.Response.Redirect(ctx.RedirectUri);
        return Task.CompletedTask;
    }
}
