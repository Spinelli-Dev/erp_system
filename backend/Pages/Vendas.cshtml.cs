// Vendas do painel: a lista (uma linha por item, como antes) é montada no servidor, e o modal de
// Consumo próprio grava pelo ConsumoProprioService (baixa o estoque sem gerar venda).
using System.Security.Claims;
using System.Text.Json;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class VendasModel : PageModel
{
    private readonly IVendaService _vendas;
    private readonly IClienteService _clientes;
    private readonly IProdutoService _produtos;
    private readonly IConsumoProprioService _consumo;
    private readonly ILogger<VendasModel> _logger;

    public VendasModel(IVendaService vendas, IClienteService clientes, IProdutoService produtos,
        IConsumoProprioService consumo, ILogger<VendasModel> logger)
    {
        _vendas = vendas;
        _clientes = clientes;
        _produtos = produtos;
        _consumo = consumo;
        _logger = logger;
    }

    public IReadOnlyList<VendaResponse> Vendas { get; private set; } = Array.Empty<VendaResponse>();
    public IReadOnlyDictionary<int, string> TelefonePorCliente { get; private set; } = new Dictionary<int, string>();

    /// <summary>Opções dos filtros, tiradas dos dados (antes eram fixas no HTML).</summary>
    public IReadOnlyList<int> Anos { get; private set; } = Array.Empty<int>();
    public IReadOnlyList<string> NomesProdutos { get; private set; } = Array.Empty<string>();

    /// <summary>Soma das vendas que valeram (canceladas não entram).</summary>
    public decimal Total { get; private set; }

    /// <summary>Produtos para a busca do modal de Consumo próprio (lidos pelo main.js).</summary>
    public string ProdutosConsumoJson { get; private set; } = "[]";

    public string? ErroConsumo { get; private set; }

    public async Task OnGetAsync() => await CarregarAsync();

    /// <summary>Consumo próprio é só para Administrador (mesma regra da API /api/ConsumoProprio).</summary>
    public bool PodeRegistrarConsumo => User.IsInRole(nameof(TipoUsuario.Administrador));

    public async Task<IActionResult> OnPostConsumoAsync(int produtoId, int? quantidade)
    {
        if (!PodeRegistrarConsumo) return await ComErroAsync("Somente administradores podem registrar consumo próprio.");
        if (produtoId <= 0) return await ComErroAsync("Selecione o produto na busca.");
        if (quantidade is null or <= 0) return await ComErroAsync("Informe a quantidade (1 ou mais).");

        try
        {
            var usuarioId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var registro = await _consumo.RegistrarConsumoAsync(
                new ConsumoProprioRequest { ProdutoId = produtoId, Quantidade = quantidade.Value, Observacao = "Registrado no painel" },
                usuarioId);
            _logger.LogInformation("[Painel] Consumo próprio de {Qtd} un. do produto {ProdutoId}.", quantidade, produtoId);
            TempData["Mensagem"] = $"Consumo próprio registrado: {quantidade} un. de {registro.NomeProduto}. Restam {registro.EstoqueRestante}.";
            return RedirectToPage();
        }
        catch (Exception ex) when (ex is InvalidOperationException or KeyNotFoundException)
        {
            return await ComErroAsync(ex.Message);
        }
    }

    private async Task<IActionResult> ComErroAsync(string mensagem)
    {
        ErroConsumo = mensagem;
        await CarregarAsync();
        return Page();
    }

    private async Task CarregarAsync()
    {
        Vendas = (await _vendas.GetAllAsync()).OrderByDescending(v => v.Data).ToList();
        TelefonePorCliente = (await _clientes.GetAllAsync()).ToDictionary(c => c.Id, c => c.Telefone);
        Total = Vendas.Where(v => v.Status != StatusVenda.Cancelada).Sum(v => v.ValorTotal);
        Anos = Vendas.Select(v => v.Data.Year).Append(DateTime.Today.Year).Distinct().OrderByDescending(a => a).ToList();

        var produtos = (await _produtos.GetAllAsync()).OrderBy(p => p.Nome).ToList();
        NomesProdutos = produtos.Select(p => p.Nome).Distinct().ToList();
        ProdutosConsumoJson = JsonSerializer.Serialize(produtos.Select(p => new
        {
            id = p.Id,
            nome = p.Nome,
            sabor = string.IsNullOrEmpty(p.Sabor) ? "Tradicional" : p.Sabor,
            peso = PainelFormatos.Peso(p.Peso),
            custo = PainelFormatos.Moeda(p.Custo),
            estoque = p.Estoque?.Quantidade ?? 0
        }));
    }

    // ── Textos das colunas (mesmos rótulos que o vendas.js usava) ────────────

    public static string RotuloStatus(StatusVenda status) => status switch
    {
        StatusVenda.Paga => "Pago",
        StatusVenda.EmEntrega => "Agendado",
        StatusVenda.Concluida => "Concluído",
        StatusVenda.Cancelada => "Cancelado",
        _ => "Pendente"
    };

    public static string RotuloPagamento(FormaPagamento? forma) => forma switch
    {
        FormaPagamento.Pix => "PIX",
        FormaPagamento.Dinheiro => "Dinheiro",
        FormaPagamento.CartaoDebito => "Cartão Débito",
        FormaPagamento.CartaoCredito => "Cartão Crédito",
        FormaPagamento.Transferencia => "Transferência",
        FormaPagamento.Outro => "Outro",
        _ => "—"
    };

    public static string TextoDesconto(VendaResponse v) => v.Desconto <= 0
        ? "R$ —"
        : v.TipoDesconto == TipoDesconto.Percentual ? $"{v.Desconto:0.##}%" : PainelFormatos.Moeda(v.Desconto);

    public static string TextoEntrega(VendaResponse v) => v.Entrega?.TipoEntrega == TipoEntrega.Entrega ? "Entrega" : "Retirada";
}
