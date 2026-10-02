// "Meu perfil": cada usuário do painel muda os próprios dados, a foto e a senha.
// (Perfil de acesso e login só o administrador muda, na tela de Usuários.)
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using FluentValidation;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

// Foto de até 2 MB (+ folga para o resto do formulário).
[RequestSizeLimit(3 * 1024 * 1024)]
[RequestFormLimits(MultipartBodyLengthLimit = 3 * 1024 * 1024)]
public class PerfilModel : PageModel
{
    private readonly IUsuarioService _usuarios;
    private readonly IFotoPerfilService _fotos;
    private readonly IValidator<PerfilUsuarioRequest> _validador;

    public PerfilModel(IUsuarioService usuarios, IFotoPerfilService fotos, IValidator<PerfilUsuarioRequest> validador)
    {
        _usuarios = usuarios;
        _fotos = fotos;
        _validador = validador;
    }

    public UsuarioResponse Usuario { get; private set; } = new();

    [BindProperty, DisplayFormat(ConvertEmptyStringToNull = false)] public string Nome { get; set; } = string.Empty;
    [BindProperty] public string? Email { get; set; }
    [BindProperty] public string? Telefone { get; set; }

    /// <summary>Erro de cada bloco da tela (aparece dentro do próprio bloco).</summary>
    public string? ErroDados { get; private set; }
    public string? ErroFoto { get; private set; }
    public string? ErroSenha { get; private set; }

    private int MeuId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    public async Task<IActionResult> OnGetAsync()
    {
        if (!await CarregarAsync()) return RedirectToPage("/Logout");
        Nome = Usuario.Nome;
        Email = Usuario.Email;
        Telefone = Usuario.Telefone;
        return Page();
    }

    public async Task<IActionResult> OnPostDadosAsync()
    {
        var request = new PerfilUsuarioRequest { Nome = Nome.Trim(), Email = Email, Telefone = Telefone };
        var validacao = await _validador.ValidateAsync(request);
        if (!validacao.IsValid) return await ComErroAsync(e => ErroDados = e, Traduzir(validacao.Errors[0].ErrorMessage), manterDigitado: true);

        try
        {
            await _usuarios.AtualizarPerfilAsync(MeuId, request);
        }
        catch (InvalidOperationException ex)
        {
            return await ComErroAsync(e => ErroDados = e, ex.Message, manterDigitado: true);
        }
        TempData["Mensagem"] = "Seus dados foram atualizados.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostFotoAsync(IFormFile? foto)
    {
        if (foto is null || foto.Length == 0) return await ComErroAsync(e => ErroFoto = e, "Escolha uma imagem.");
        try
        {
            await using var arquivo = foto.OpenReadStream();
            var preparada = await _fotos.PrepararAsync(arquivo, foto.Length);
            await _usuarios.DefinirFotoAsync(MeuId, preparada);
        }
        catch (InvalidOperationException ex)
        {
            return await ComErroAsync(e => ErroFoto = e, ex.Message);
        }
        TempData["Mensagem"] = "Foto atualizada.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostRemoverFotoAsync()
    {
        await _usuarios.DefinirFotoAsync(MeuId, null);
        TempData["Mensagem"] = "Foto removida.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostSenhaAsync(string? senhaAtual, string? novaSenha, string? confirmacao)
    {
        if (novaSenha != confirmacao) return await ComErroAsync(e => ErroSenha = e, "A confirmação não confere com a nova senha.");
        try
        {
            await _usuarios.TrocarSenhaAsync(MeuId, senhaAtual ?? string.Empty, novaSenha ?? string.Empty);
        }
        catch (InvalidOperationException ex)
        {
            return await ComErroAsync(e => ErroSenha = e, ex.Message);
        }
        TempData["Mensagem"] = "Senha alterada. Use a nova senha no próximo acesso.";
        return RedirectToPage();
    }

    private async Task<IActionResult> ComErroAsync(Action<string> definir, string mensagem, bool manterDigitado = false)
    {
        definir(mensagem);
        await CarregarAsync();
        // Erro no bloco de dados: volta o que foi digitado. Nos outros blocos (foto, senha), os dados não
        // vieram no formulário — mostra os gravados.
        if (!manterDigitado)
        {
            Nome = Usuario.Nome;
            Email = Usuario.Email;
            Telefone = Usuario.Telefone;
        }
        return Page();
    }

    private async Task<bool> CarregarAsync()
    {
        var usuario = await _usuarios.GetByIdAsync(MeuId);
        if (usuario is null) return false;
        Usuario = usuario;
        return true;
    }

    private static string Traduzir(string mensagem) => mensagem
        .Replace("e obrigatorio", "é obrigatório").Replace("invalido", "inválido");
}
