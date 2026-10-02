// Produtos do painel: lista montada no servidor; o modal cadastra/altera pelo ProdutoService (o mesmo da API).
// No cadastro, o "Estoque" informado vira o estoque inicial (com movimentação de entrada registrada);
// na alteração ele só é exibido — mudar estoque é na tela de Estoque, que registra o motivo.
using FluentValidation;
using System.ComponentModel.DataAnnotations;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class ProdutoForm
{
    /// <summary>0 = produto novo.</summary>
    public int Id { get; set; }
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Nome { get; set; } = string.Empty;
    public string? Sabor { get; set; }
    public string? Peso { get; set; }
    public string? Custo { get; set; }
    public string? Preco { get; set; }
    /// <summary>Só no cadastro: estoque inicial.</summary>
    public int? Estoque { get; set; }
    /// <summary>Nome do enum TipoProduto (ex.: "Massa").</summary>
    public string? Tipo { get; set; }
    public string? Observacao { get; set; }
}

public class ProdutosModel : PageModel
{
    private readonly IProdutoService _produtos;
    private readonly IEstoqueService _estoque;
    private readonly IValidator<ProdutoRequest> _validador;
    private readonly ILogger<ProdutosModel> _logger;

    public ProdutosModel(IProdutoService produtos, IEstoqueService estoque, IValidator<ProdutoRequest> validador,
        ILogger<ProdutosModel> logger)
    {
        _produtos = produtos;
        _estoque = estoque;
        _validador = validador;
        _logger = logger;
    }

    public IReadOnlyList<ProdutoResponse> Produtos { get; private set; } = Array.Empty<ProdutoResponse>();

    [BindProperty] public ProdutoForm Produto { get; set; } = new();

    public IReadOnlyList<string> ErrosFormulario { get; private set; } = Array.Empty<string>();

    public async Task OnGetAsync() => await CarregarAsync();

    /// <summary>Cadastrar e alterar produto é só para Administrador (mesma regra do POST/PUT /api/Produto).</summary>
    public bool PodeEditar => User.IsInRole(nameof(TipoUsuario.Administrador));

    public async Task<IActionResult> OnPostAsync()
    {
        if (!PodeEditar)
        {
            ErrosFormulario = new[] { "Somente administradores podem cadastrar ou alterar produtos." };
            await CarregarAsync();
            return Page();
        }

        var erros = new List<string>();
        var peso = PainelFormatos.LerPeso(Produto.Peso);
        var custo = PainelFormatos.LerMoeda(Produto.Custo);
        var preco = PainelFormatos.LerMoeda(Produto.Preco);
        if (peso is null) erros.Add("Informe o peso (ex.: 250g).");
        if (custo is null) erros.Add("Informe o custo (ex.: R$ 18,90).");
        if (preco is null) erros.Add("Informe o preço (ex.: R$ 39,90).");
        if (!Enum.TryParse<TipoProduto>(Produto.Tipo, out var tipo) || !Enum.IsDefined(tipo)) erros.Add("Escolha o tipo do produto.");
        var novo = Produto.Id == 0;
        if (novo && (Produto.Estoque is null || Produto.Estoque < 0)) erros.Add("Informe o estoque inicial (0 ou mais).");

        var request = new ProdutoUpdateRequest
        {
            Nome = (Produto.Nome ?? string.Empty).Trim(), // campo vazio chega como null
            Sabor = Produto.Sabor,
            Observacao = Produto.Observacao,
            Peso = peso ?? 0,
            Custo = custo ?? 0,
            PrecoVenda = preco ?? 0,
            Tipo = tipo,
            MotivoAlteracao = "Alterado no painel"
        };
        if (erros.Count == 0)
        {
            var validacao = await _validador.ValidateAsync(request);
            erros.AddRange(validacao.Errors.Select(e => Traduzir(e.ErrorMessage)));
        }
        if (erros.Count > 0)
        {
            ErrosFormulario = erros.Distinct().ToList();
            await CarregarAsync();
            return Page();
        }

        if (novo)
        {
            var criado = await _produtos.CreateAsync(request);
            var estoque = await _estoque.GarantirEstoqueAsync(criado.Id, PainelFormatos.AlertaMinimoPadrao);
            if (Produto.Estoque > 0)
            {
                await _estoque.RegistrarMovimentacaoAsync(new MovimentacaoEstoqueRequest
                {
                    EstoqueId = estoque.Id, Tipo = TipoMovimentacao.Entrada, Quantidade = Produto.Estoque.Value,
                    Motivo = "Estoque inicial (cadastro do produto)"
                });
            }
            _logger.LogInformation("[Painel] Produto {Id} cadastrado com estoque {Qtd}.", criado.Id, Produto.Estoque);
            TempData["Mensagem"] = $"Produto {criado.Nome} cadastrado.";
        }
        else
        {
            var atualizado = await _produtos.UpdateAsync(Produto.Id, request);
            TempData["Mensagem"] = atualizado is null ? "Este produto não existe mais." : $"Produto {atualizado.Nome} atualizado.";
        }
        return RedirectToPage();
    }

    private async Task CarregarAsync()
    {
        Produtos = (await _produtos.GetAllAsync())
            .OrderBy(p => p.Nome).ThenBy(p => p.Sabor)
            .ToList();
    }

    private static string Traduzir(string mensagem) => mensagem
        .Replace("e obrigatorio", "é obrigatório")
        .Replace("Preco de venda", "Preço de venda")
        .Replace("nao pode", "não pode")
        .Replace("invalido", "inválido");
}
