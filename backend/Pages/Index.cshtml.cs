using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

/// <summary>Raiz do site: o painel abre no Dashboard (ou no login, se não houver sessão).</summary>
public class IndexModel : PageModel
{
    public IActionResult OnGet() => RedirectToPage("/Dashboard");
}
