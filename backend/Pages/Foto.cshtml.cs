// Foto de perfil de um usuário do painel (/Foto/{id}?v=versão). Só para quem está logado.
// A URL leva a versão da foto, então o navegador pode guardar a imagem por muito tempo:
// quando a foto muda, muda a URL.
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class FotoModel : PageModel
{
    private readonly IUsuarioService _usuarios;
    public FotoModel(IUsuarioService usuarios) { _usuarios = usuarios; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        var foto = await _usuarios.ObterFotoAsync(id);
        if (foto is null) return NotFound();

        Response.Headers.CacheControl = "private, max-age=31536000, immutable";
        return File(foto.Value.Foto, "image/jpeg");
    }
}
