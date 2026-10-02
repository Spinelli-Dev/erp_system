// Sair do painel: apaga o cookie de sessão. Só por POST (o botão "Sair" do menu envia um formulário
// com token antifalsificação), para um link de outro site não conseguir deslogar ninguém.
using MaxiMassasAPI.Configurations;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class LogoutModel : PageModel
{
    public IActionResult OnGet() => RedirectToPage("/Dashboard");

    public async Task<IActionResult> OnPostAsync()
    {
        await HttpContext.SignOutAsync(PainelAuth.Scheme);
        return RedirectToPage("/Login");
    }
}
