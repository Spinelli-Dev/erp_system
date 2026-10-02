// Esqueci minha senha (painel), passo 2: a pessoa abre o link do e-mail (?token=...) e cria a nova senha.
// Link vale 1 hora e é de uso único; a nova senha segue a PoliticaSenha (regras em AuthService).
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class RedefinirSenhaModel : PageModel
{
    private readonly IAuthService _auth;

    public RedefinirSenhaModel(IAuthService auth) => _auth = auth;

    [BindProperty(SupportsGet = true)] public string Token { get; set; } = string.Empty;
    [BindProperty] public string NovaSenha { get; set; } = string.Empty;
    [BindProperty] public string ConfirmarSenha { get; set; } = string.Empty;

    public bool LinkValido { get; private set; }
    public string? Erro { get; private set; }

    public async Task OnGetAsync()
    {
        // O token vai na URL; não deixa a página "vazar" o endereço para outros sites.
        Response.Headers["Referrer-Policy"] = "no-referrer";
        LinkValido = await _auth.TokenValidoAsync(Token);
    }

    public async Task<IActionResult> OnPostAsync()
    {
        Response.Headers["Referrer-Policy"] = "no-referrer";
        try
        {
            await _auth.RedefinirSenhaAsync(new ResetPasswordRequest
            {
                Token = Token ?? string.Empty,
                NovaSenha = NovaSenha ?? string.Empty,
                ConfirmarSenha = ConfirmarSenha ?? string.Empty
            });
        }
        catch (InvalidOperationException ex)
        {
            Erro = ex.Message;
            LinkValido = await _auth.TokenValidoAsync(Token ?? string.Empty);
            return Page();
        }

        TempData["Aviso"] = "Senha alterada! Entre com a nova senha.";
        return RedirectToPage("/Login");
    }
}
