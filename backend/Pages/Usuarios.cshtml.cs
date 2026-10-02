// Usuários do painel — só para Administrador: cadastrar, editar (nome, contato, perfil),
// redefinir a senha de alguém e ativar/desativar. As regras (login único, senha forte, nunca
// ficar sem administrador ativo) estão no UsuarioService, o mesmo da API /api/Usuario.
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using FluentValidation;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class UsuarioForm
{
    /// <summary>0 = usuário novo.</summary>
    public int Id { get; set; }
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Nome { get; set; } = string.Empty;
    /// <summary>Só no cadastro (depois não muda).</summary>
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Login { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public TipoUsuario Tipo { get; set; } = TipoUsuario.Operador;
    /// <summary>Obrigatória no cadastro; na edição, preenchida = redefinir.</summary>
    public string? Senha { get; set; }
}

public class UsuariosModel : PageModel
{
    private readonly IUsuarioService _usuarios;
    private readonly IValidator<UsuarioRequest> _validadorNovo;
    private readonly IValidator<UsuarioUpdateRequest> _validadorEdicao;
    private readonly ILogger<UsuariosModel> _logger;

    public UsuariosModel(IUsuarioService usuarios, IValidator<UsuarioRequest> validadorNovo,
        IValidator<UsuarioUpdateRequest> validadorEdicao, ILogger<UsuariosModel> logger)
    {
        _usuarios = usuarios;
        _validadorNovo = validadorNovo;
        _validadorEdicao = validadorEdicao;
        _logger = logger;
    }

    public IReadOnlyList<UsuarioResponse> Usuarios { get; private set; } = Array.Empty<UsuarioResponse>();

    [BindProperty] public UsuarioForm Usuario { get; set; } = new();

    public IReadOnlyList<string> ErrosFormulario { get; private set; } = Array.Empty<string>();
    public string? Erro { get; private set; }

    public int MeuId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Operador que abrir o endereço volta ao Dashboard com o aviso.</summary>
    public override void OnPageHandlerExecuting(PageHandlerExecutingContext context)
    {
        if (!User.IsInRole(nameof(TipoUsuario.Administrador)))
        {
            TempData["Mensagem"] = "A tela de Usuários é só para administradores.";
            context.Result = RedirectToPage("/Dashboard");
        }
    }

    public async Task OnGetAsync() => await CarregarAsync();

    public async Task<IActionResult> OnPostSalvarAsync()
    {
        var novo = Usuario.Id == 0;
        if (!novo && Usuario.Id == MeuId)
        {
            // O próprio administrador não muda o próprio perfil aqui (evita se trancar fora);
            // os dados pessoais ele muda em "Meu perfil".
            var eu = await _usuarios.GetByIdAsync(MeuId);
            if (eu is not null && eu.Tipo != Usuario.Tipo)
                return await ComErrosAsync("Você não pode mudar o seu próprio perfil de acesso. Peça a outro administrador.");
        }

        try
        {
            if (novo)
            {
                var request = new UsuarioRequest
                {
                    Nome = Usuario.Nome.Trim(), Login = Usuario.Login.Trim(), Senha = Usuario.Senha ?? string.Empty,
                    Tipo = Usuario.Tipo, Email = Usuario.Email, Telefone = Usuario.Telefone
                };
                var validacao = await _validadorNovo.ValidateAsync(request);
                if (!validacao.IsValid) return await ComErrosAsync(validacao.Errors.Select(e => e.ErrorMessage).ToArray());

                var criado = await _usuarios.CreateAsync(request);
                _logger.LogInformation("[Painel] Usuário {Login} cadastrado por {Admin}.", criado.Login, User.Identity?.Name);
                TempData["Mensagem"] = $"Usuário {criado.Login} cadastrado como {criado.TipoDescricao}.";
            }
            else
            {
                var request = new UsuarioUpdateRequest
                {
                    Nome = Usuario.Nome.Trim(), Tipo = Usuario.Tipo, Email = Usuario.Email, Telefone = Usuario.Telefone,
                    Senha = string.IsNullOrEmpty(Usuario.Senha) ? null : Usuario.Senha
                };
                var validacao = await _validadorEdicao.ValidateAsync(request);
                if (!validacao.IsValid) return await ComErrosAsync(validacao.Errors.Select(e => e.ErrorMessage).ToArray());

                var atualizado = await _usuarios.UpdateAsync(Usuario.Id, request);
                if (atualizado is null) return await ComErrosAsync("Este usuário não existe mais.");
                TempData["Mensagem"] = request.Senha is null
                    ? $"Usuário {atualizado.Login} atualizado."
                    : $"Usuário {atualizado.Login} atualizado e com senha nova. Passe a senha a ele.";
            }
        }
        catch (InvalidOperationException ex)
        {
            return await ComErrosAsync(ex.Message);
        }
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostAtivoAsync(int id, bool ativo)
    {
        if (id == MeuId) return await ComErroAsync("Você não pode desativar o seu próprio usuário.");
        var usuario = await _usuarios.GetByIdAsync(id);
        if (usuario is null) return await ComErroAsync("Este usuário não existe mais.");

        try
        {
            await _usuarios.UpdateAsync(id, new UsuarioUpdateRequest
            {
                Nome = usuario.Nome, Tipo = usuario.Tipo, Email = usuario.Email, Telefone = usuario.Telefone, Ativo = ativo
            });
        }
        catch (InvalidOperationException ex)
        {
            return await ComErroAsync(ex.Message);
        }
        _logger.LogInformation("[Painel] Usuário {Login} {Acao} por {Admin}.", usuario.Login, ativo ? "ativado" : "desativado", User.Identity?.Name);
        TempData["Mensagem"] = ativo
            ? $"Usuário {usuario.Login} ativado: já pode entrar no sistema."
            : $"Usuário {usuario.Login} desativado: não entra mais no sistema (o histórico dele continua).";
        return RedirectToPage();
    }

    private async Task<IActionResult> ComErrosAsync(params string[] erros)
    {
        ErrosFormulario = erros.Select(Traduzir).Distinct().ToList();
        Usuario.Senha = null; // não devolve a senha digitada para a página
        await CarregarAsync();
        return Page();
    }

    private async Task<IActionResult> ComErroAsync(string mensagem)
    {
        Erro = mensagem;
        await CarregarAsync();
        return Page();
    }

    private async Task CarregarAsync()
    {
        // Ativos primeiro, depois por nome.
        Usuarios = (await _usuarios.GetAllAsync()).OrderByDescending(u => u.Ativo).ThenBy(u => u.Nome).ToList();
    }

    private static string Traduzir(string mensagem) => mensagem
        .Replace("e obrigatorio", "é obrigatório").Replace("invalido", "inválido")
        .Replace("numeros", "números").Replace("Login deve", "O login deve");
}
