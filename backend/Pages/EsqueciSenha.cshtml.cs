// Esqueci minha senha (painel), passo 1: pede o e-mail ou login e manda o link por e-mail.
// A resposta é sempre a mesma, exista ou não a conta (regras em AuthService).
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class EsqueciSenhaModel : PageModel
{
    private readonly IAuthService _auth;

    public EsqueciSenhaModel(IAuthService auth) => _auth = auth;

    [BindProperty] public string? EmailOuLogin { get; set; }

    public bool Enviado { get; private set; }
    public string? Erro { get; private set; }

    public IActionResult OnGet()
    {
        if (User.Identity?.IsAuthenticated == true) return Redirect("/Perfil"); // logado troca a senha no perfil
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (string.IsNullOrWhiteSpace(EmailOuLogin))
        {
            Erro = "Informe seu e-mail ou usuário.";
            return Page();
        }

        await _auth.SolicitarResetSenhaAsync(EmailOuLogin);
        Enviado = true;
        return Page();
    }
}
