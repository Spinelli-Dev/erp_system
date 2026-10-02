// Base das telas de venda do painel (Nova venda e Alterar venda — mesmo layout de PDV).
//
// O PDV continua interativo no navegador (contadores, comanda calculada ao vivo, pdv.js), mas:
//   - os dados da tela (clientes, produtos, estoque, regra da taxa) vêm do servidor, embutidos na página;
//   - "Salvar Venda" envia um formulário (POST) com o estado da comanda em campos ocultos, e quem grava
//     é o servidor, pelo mesmo VendaService da API (validação de estoque, baixa atômica, transação).
using System.Globalization;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using System.Text.Json;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

/// <summary>Campos ocultos do formulário do PDV, preenchidos pelo pdv.js antes de enviar.</summary>
public class VendaForm
{
    public int ClienteId { get; set; }
    /// <summary>[{"produtoId":1,"quantidade":2}]</summary>
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string ItensJson { get; set; } = "[]";
    /// <summary>"Retirada" ou "Delivery" (rótulos dos botões da tela).</summary>
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string TipoEntrega { get; set; } = string.Empty;
    public string? DataAgendada { get; set; }
    public string? HoraAgendada { get; set; }
    public string? Rua { get; set; }
    public string? Numero { get; set; }
    public string? Bairro { get; set; }
    public string? Cidade { get; set; }
    public string? Uf { get; set; }
    public string? Complemento { get; set; }
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Plataforma { get; set; } = string.Empty;
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Pagamento { get; set; } = string.Empty;
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Status { get; set; } = string.Empty;
    /// <summary>"RS" ou "PCT".</summary>
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string TipoDesconto { get; set; } = "RS";
    /// <summary>Texto com ponto decimal (vem do JavaScript), lido com cultura invariante.</summary>
    public string? Desconto { get; set; }
    public string? Observacao { get; set; }
}

public record ItemForm(int ProdutoId, int Quantidade);

public abstract class PdvPageModel : PageModel
{
    protected readonly IVendaService Vendas;
    protected readonly IClienteService Clientes;
    protected readonly IProdutoService Produtos;
    protected readonly IConfiguracaoEntregaService ConfigEntrega;

    protected PdvPageModel(IVendaService vendas, IClienteService clientes, IProdutoService produtos,
        IConfiguracaoEntregaService configEntrega)
    {
        Vendas = vendas;
        Clientes = clientes;
        Produtos = produtos;
        ConfigEntrega = configEntrega;
    }

    [BindProperty] public VendaForm Venda { get; set; } = new();

    /// <summary>Título da tela ("Nova Venda" / "Editar Venda").</summary>
    public abstract string Titulo { get; }

    /// <summary>Mensagem de erro do último envio (estoque insuficiente, campo faltando...).</summary>
    public string? Erro { get; protected set; }

    /// <summary>Dados para o pdv.js: catálogo, regra da taxa e o estado da comanda a restaurar.</summary>
    public string DadosJson { get; private set; } = "{}";

    // ── Rótulos da tela ⇄ enums do domínio ──────────────────────────────────

    protected static readonly Dictionary<string, FormaPagamento> PagamentoPorRotulo = new()
    {
        ["PIX"] = FormaPagamento.Pix,
        ["Dinheiro"] = FormaPagamento.Dinheiro,
        ["Cartão Débito"] = FormaPagamento.CartaoDebito,
        ["Cartão Crédito"] = FormaPagamento.CartaoCredito,
    };

    /// <summary>Status da tela → (status da venda, status do pagamento). "Agendado" = EmEntrega (convenção da tela de Vendas).</summary>
    protected static readonly Dictionary<string, (StatusVenda Venda, StatusPagamento Pagamento)> StatusPorRotulo = new()
    {
        ["Concluído"] = (StatusVenda.Concluida, StatusPagamento.Pago),
        ["Agendado"] = (StatusVenda.EmEntrega, StatusPagamento.Pendente),
        ["Pendente Pagamento"] = (StatusVenda.Aberta, StatusPagamento.Pendente),
        ["Cancelado"] = (StatusVenda.Cancelada, StatusPagamento.Cancelado),
    };

    protected static string RotuloPagamento(FormaPagamento? forma) =>
        PagamentoPorRotulo.FirstOrDefault(p => p.Value == forma).Key ?? string.Empty;

    protected static string RotuloStatus(StatusVenda status) => status switch
    {
        StatusVenda.Concluida or StatusVenda.Paga => "Concluído",
        StatusVenda.EmEntrega => "Agendado",
        StatusVenda.Cancelada => "Cancelado",
        _ => "Pendente Pagamento"
    };

    protected int UsuarioId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Leitura do formulário ────────────────────────────────────────────────

    protected List<ItemForm> LerItens()
    {
        try
        {
            var itens = JsonSerializer.Deserialize<List<ItemForm>>(Venda.ItensJson,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new();
            return itens.Where(i => i.Quantidade > 0).ToList();
        }
        catch (JsonException)
        {
            return new();
        }
    }

    protected decimal LerDesconto() =>
        decimal.TryParse(Venda.Desconto, NumberStyles.Number, CultureInfo.InvariantCulture, out var d) ? Math.Max(0, d) : 0;

    protected static DateTime? LerData(string? texto) =>
        DateTime.TryParseExact(texto?.Trim(), "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;

    protected static string? LerHora(string? texto) =>
        TimeSpan.TryParseExact(texto?.Trim(), @"hh\:mm", CultureInfo.InvariantCulture, out var h) && h < TimeSpan.FromDays(1)
            ? texto!.Trim()
            : null;

    // ── Dados da tela ────────────────────────────────────────────────────────

    /// <summary>
    /// Monta o JSON lido pelo pdv.js. [estado] é a comanda a restaurar (edição, ou o formulário
    /// devolvido com erro); nulo = comanda vazia.
    /// </summary>
    protected async Task CarregarDadosAsync(object? estado, string modo, int? vendaId = null)
    {
        var clientes = await Clientes.GetAllAsync();
        var produtos = await Produtos.GetAllAsync();
        var regra = await ConfigEntrega.ObterAsync();

        var dados = new
        {
            modo,
            vendaId,
            clientes = clientes.OrderBy(c => c.Nome).Select(ClienteParaTela),
            produtos = produtos.OrderBy(p => p.Nome).ThenBy(p => p.Sabor).Select(p => new
            {
                id = p.Id,
                nome = p.Nome,
                sabor = string.IsNullOrWhiteSpace(p.Sabor) ? "Tradicional" : p.Sabor,
                peso = $"{p.Peso:0.##}g",
                preco = p.PrecoVenda,
                estoque = p.Estoque?.Quantidade ?? 0
            }),
            regraEntrega = new { taxa = regra.TaxaEntrega, minimoGratis = regra.PedidoMinimoEntregaGratis },
            sugestoes = await SugestoesPorClienteAsync(),
            estado
        };
        DadosJson = JsonSerializer.Serialize(dados, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
    }

    /// <summary>Quantos produtos aparecem no card "Pedido Sugerido".</summary>
    private const int MaximoSugestoes = 3;

    /// <summary>
    /// "Pedido Sugerido": para cada cliente, os produtos que ele mais comprou (em unidades, só vendas que
    /// valeram), com a quantidade que ele costuma levar por pedido — é o que o card oferece para adicionar.
    /// { "12": [ { produtoId: 1, totalComprado: 9, porPedido: 3 }, ... ] }
    /// </summary>
    private async Task<Dictionary<string, object>> SugestoesPorClienteAsync()
    {
        var vendas = (await Vendas.GetAllAsync()).Where(v => v.Status != StatusVenda.Cancelada);
        return vendas
            .GroupBy(v => v.ClienteId)
            .ToDictionary(
                g => g.Key.ToString(),
                g => (object)g.SelectMany(v => v.Itens.Select(i => (v.Id, i.ProdutoId, i.Quantidade)))
                    .GroupBy(i => i.ProdutoId)
                    .Select(p => new
                    {
                        produtoId = p.Key,
                        totalComprado = p.Sum(i => i.Quantidade),
                        porPedido = (int)Math.Max(1, Math.Round((double)p.Sum(i => i.Quantidade) / p.Select(i => i.Id).Distinct().Count()))
                    })
                    .OrderByDescending(p => p.totalComprado)
                    .Take(MaximoSugestoes)
                    .ToList());
    }

    protected static object ClienteParaTela(ClienteResponse c) => new
    {
        id = c.Id,
        nome = c.Nome,
        tel = c.Telefone,
        rua = c.Logradouro,
        num = c.Numero,
        bairro = c.Bairro,
        cid = c.Cidade,
        uf = c.Estado,
        comp = c.Complemento ?? string.Empty
    };

    /// <summary>A comanda como estava no formulário enviado — para não perder o que foi digitado quando há erro.</summary>
    protected async Task<object> EstadoDoFormularioAsync()
    {
        var cliente = Venda.ClienteId > 0 ? await Clientes.GetByIdAsync(Venda.ClienteId) : null;
        return new
        {
            cliente = cliente is null ? null : ClienteParaTela(cliente),
            itens = LerItens().Select(i => new { idProduto = i.ProdutoId, qtd = i.Quantidade }),
            tipoDesconto = Venda.TipoDesconto == "PCT" ? "PCT" : "RS",
            valorDesconto = LerDesconto(),
            tipoEntrega = Venda.TipoEntrega,
            plataforma = Venda.Plataforma,
            pagamento = Venda.Pagamento,
            status = Venda.Status,
            obs = Venda.Observacao ?? string.Empty,
            dataAgendada = Venda.DataAgendada ?? string.Empty,
            horaAgendada = Venda.HoraAgendada ?? string.Empty,
            endereco = new
            {
                rua = Venda.Rua ?? "", num = Venda.Numero ?? "", bairro = Venda.Bairro ?? "",
                cid = Venda.Cidade ?? "", uf = Venda.Uf ?? "", comp = Venda.Complemento ?? ""
            }
        };
    }
}
