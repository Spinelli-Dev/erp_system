// Estoque do painel: lista montada no servidor, mais as duas ações da tela, gravadas pelo EstoqueService:
//   - Ajustar: define a quantidade exata (contagem) e registra um Ajuste "de X para Y";
//   - Reposição: soma as quantidades informadas, com uma Entrada para cada produto.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class ItemReposicaoForm
{
    public int ProdutoId { get; set; }
    public int Quantidade { get; set; }
}

public class EstoqueModel : PageModel
{
    private readonly IProdutoService _produtos;
    private readonly IEstoqueService _estoque;
    private readonly ILogger<EstoqueModel> _logger;

    public EstoqueModel(IProdutoService produtos, IEstoqueService estoque, ILogger<EstoqueModel> logger)
    {
        _produtos = produtos;
        _estoque = estoque;
        _logger = logger;
    }

    public IReadOnlyList<ProdutoResponse> Produtos { get; private set; } = Array.Empty<ProdutoResponse>();

    /// <summary>Produtos agrupados por nome, como nos cartões do modal de Reposição.</summary>
    public IEnumerable<IGrouping<string, ProdutoResponse>> GruposReposicao => Produtos.GroupBy(p => p.Nome);

    /// <summary>Mensagem de erro de uma ação recusada (mostrada no topo da página).</summary>
    public string? Erro { get; private set; }

    public async Task OnGetAsync() => await CarregarAsync();

    /// <summary>Ajustar para uma quantidade exata é só para o gestor (Administrador); a reposição é para todos.</summary>
    public bool PodeAjustar => User.IsInRole(nameof(TipoUsuario.Administrador));

    public async Task<IActionResult> OnPostAjusteAsync(int produtoId, int? quantidade)
    {
        if (!PodeAjustar) return await ComErroAsync("Somente administradores podem ajustar o estoque. Para dar entrada em mercadoria, use a Reposição.");
        var produto = await _produtos.GetByIdAsync(produtoId);
        if (produto is null) return await ComErroAsync("Este produto não existe mais.");
        if (quantidade is null or < 0) return await ComErroAsync("Informe o novo estoque (0 ou mais).");

        try
        {
            await _estoque.AjustarQuantidadeAsync(produtoId, quantidade.Value, "Ajuste manual no painel");
        }
        catch (InvalidOperationException ex)
        {
            return await ComErroAsync(ex.Message);
        }

        TempData["Mensagem"] = $"Estoque de {NomeCompleto(produto)} ajustado para {quantidade} un.";
        return RedirectToPage();
    }

    public async Task<IActionResult> OnPostReposicaoAsync(List<ItemReposicaoForm> itens)
    {
        var repor = itens.Where(i => i.Quantidade > 0).ToList();
        if (repor.Count == 0) return await ComErroAsync("Informe a quantidade de pelo menos um produto para repor.");

        var unidades = 0;
        foreach (var item in repor)
        {
            var estoque = await _estoque.GarantirEstoqueAsync(item.ProdutoId, PainelFormatos.AlertaMinimoPadrao);
            await _estoque.RegistrarMovimentacaoAsync(new MovimentacaoEstoqueRequest
            {
                EstoqueId = estoque.Id,
                Tipo = TipoMovimentacao.Entrada,
                Quantidade = item.Quantidade,
                Motivo = "Reposição pelo painel"
            });
            unidades += item.Quantidade;
        }

        _logger.LogInformation("[Painel] Reposição de {N} produto(s), {U} unidades.", repor.Count, unidades);
        TempData["Mensagem"] = $"Reposição registrada: {unidades} unidade(s) em {repor.Count} produto(s).";
        return RedirectToPage();
    }

    private async Task<IActionResult> ComErroAsync(string mensagem)
    {
        Erro = mensagem;
        await CarregarAsync();
        return Page();
    }

    private async Task CarregarAsync()
    {
        Produtos = (await _produtos.GetAllAsync()).OrderBy(p => p.Nome).ThenBy(p => p.Sabor).ToList();
    }

    public static string NomeCompleto(ProdutoResponse p) => string.IsNullOrEmpty(p.Sabor) ? p.Nome : $"{p.Nome} {p.Sabor}";
}
