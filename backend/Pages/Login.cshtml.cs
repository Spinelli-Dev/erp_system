// Login do painel: confere usuário e senha (hash BCrypt) no servidor e cria o cookie de sessão.
using MaxiMassasAPI.Configurations;
using MaxiMassasAPI.Repositories;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class LoginModel : PageModel
{
    private readonly IUsuarioRepository _usuarios;
    private readonly ILogger<LoginModel> _logger;

    public LoginModel(IUsuarioRepository usuarios, ILogger<LoginModel> logger)
    {
        _usuarios = usuarios;
        _logger = logger;
    }

    [BindProperty] public string Usuario { get; set; } = string.Empty;
    [BindProperty] public string Senha { get; set; } = string.Empty;

    /// <summary>Página que pediu o login (ex.: /Vendas); volta para ela depois de entrar.</summary>
    [BindProperty(SupportsGet = true)] public string? ReturnUrl { get; set; }

    public string? Erro { get; private set; }

    public IActionResult OnGet()
    {
        // Já tem sessão: não mostra o login de novo.
        if (User.Identity?.IsAuthenticated == true) return Redirect(Destino());
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (string.IsNullOrWhiteSpace(Usuario) || string.IsNullOrEmpty(Senha))
        {
            Erro = "Informe usuário e senha.";
            return Page();
        }

        var usuario = await _usuarios.GetByLoginAsync(Usuario.Trim());
        if (usuario is null || !BCrypt.Net.BCrypt.Verify(Senha, usuario.Senha))
        {
            Erro = "Usuário ou senha incorretos. Tente novamente.";
            Senha = string.Empty;
            return Page();
        }
        // Só avisa que está desativado depois de a senha conferir (não revela isso para quem chuta senhas).
        if (!usuario.Ativo)
        {
            Erro = "Este usuário está desativado. Fale com o administrador do sistema.";
            Senha = string.Empty;
            return Page();
        }

        await HttpContext.SignInAsync(PainelAuth.Scheme, PainelAuth.CriarPrincipal(usuario, PainelAuth.Scheme));
        _logger.LogInformation("[Painel] Login de {Login}", usuario.Login);
        return Redirect(Destino());
    }

    /// <summary>Só aceita voltar para páginas do próprio painel (evita redirecionar para outro site).</summary>
    private string Destino() => !string.IsNullOrEmpty(ReturnUrl) && Url.IsLocalUrl(ReturnUrl) ? ReturnUrl : "/Dashboard";
}
