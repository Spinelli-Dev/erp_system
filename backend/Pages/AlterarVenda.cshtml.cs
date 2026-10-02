// Editar venda: mesma tela do PDV, mas só status, forma de pagamento, plataforma e observação mudam.
// Itens, cliente e entrega ficam travados — o estoque já foi baixado por eles. Para trocar itens,
// cancela-se a venda (os itens voltam ao estoque) e registra-se outra.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Pages;

public class AlterarVendaModel : PdvPageModel
{
    private readonly ILogger<AlterarVendaModel> _logger;

    public AlterarVendaModel(IVendaService vendas, IClienteService clientes, IProdutoService produtos,
        IConfiguracaoEntregaService configEntrega, ILogger<AlterarVendaModel> logger)
        : base(vendas, clientes, produtos, configEntrega)
    {
        _logger = logger;
    }

    public override string Titulo => "Editar Venda";

    [BindProperty(SupportsGet = true)] public int Id { get; set; }

    public async Task<IActionResult> OnGetAsync()
    {
        var venda = await Vendas.GetByIdAsync(Id);
        if (venda is null) return VendaNaoEncontrada();

        await CarregarDadosAsync(await EstadoDaVendaAsync(venda), modo: "edicao", vendaId: venda.Id);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        var venda = await Vendas.GetByIdAsync(Id);
        if (venda is null) return VendaNaoEncontrada();

        if (!StatusPorRotulo.TryGetValue(Venda.Status, out var status)) Erro = "Escolha o status da venda.";
        else if (!PagamentoPorRotulo.TryGetValue(Venda.Pagamento, out _)) Erro = "Escolha a forma de pagamento.";
        else if (string.IsNullOrWhiteSpace(Venda.Plataforma)) Erro = "Escolha a plataforma do pedido.";
        else if ((Venda.Observacao?.Length ?? 0) > 500) Erro = "A observação pode ter no máximo 500 caracteres.";

        if (Erro is null)
        {
            try
            {
                await Vendas.UpdateAsync(Id, new VendaUpdateRequest
                {
                    Status = status.Venda,
                    StatusPagamento = status.Pagamento,
                    // Mantém a data de um pagamento que já tinha sido feito.
                    DataPagamento = venda.Pagamento?.DataPagamento,
                    Origem = Venda.Plataforma.Trim(),
                    FormaPagamento = PagamentoPorRotulo[Venda.Pagamento],
                    Observacao = Venda.Observacao ?? string.Empty
                });
                _logger.LogInformation("[Painel] Venda #{VendaId} alterada para {Status}.", Id, status.Venda);
                TempData["Mensagem"] = status.Venda == StatusVenda.Cancelada && venda.Status != StatusVenda.Cancelada
                    ? $"Venda #{Id} cancelada. Os itens voltaram ao estoque."
                    : $"Venda #{Id} atualizada.";
                return RedirectToPage("/Vendas");
            }
            catch (InvalidOperationException ex)
            {
                Erro = ex.Message; // ex.: tentar reabrir uma venda cancelada
            }
        }

        // Devolve a tela com a venda como está no banco, mantendo as escolhas editáveis do formulário.
        var estado = await EstadoDaVendaAsync(venda, Venda);
        await CarregarDadosAsync(estado, modo: "edicao", vendaId: venda.Id);
        return Page();
    }

    private IActionResult VendaNaoEncontrada()
    {
        TempData["Mensagem"] = $"Venda #{Id} não encontrada.";
        return RedirectToPage("/Vendas");
    }

    /// <summary>A comanda montada a partir da venda gravada (com as escolhas de [form] por cima, se houver).</summary>
    private async Task<object> EstadoDaVendaAsync(VendaResponse v, VendaForm? form = null)
    {
        var cliente = await Clientes.GetByIdAsync(v.ClienteId);
        var entrega = v.Entrega;
        var delivery = entrega?.TipoEntrega == TipoEntrega.Entrega;

        return new
        {
            cliente = cliente is null
                ? new { id = v.ClienteId, nome = v.NomeCliente, tel = "", rua = "", num = "", bairro = "", cid = "", uf = "", comp = "" }
                : ClienteParaTela(cliente),
            itens = v.Itens.Select(i => new { idProduto = i.ProdutoId, qtd = i.Quantidade }),
            tipoDesconto = v.TipoDesconto == TipoDesconto.Percentual ? "PCT" : "RS",
            valorDesconto = v.Desconto,
            // A taxa cobrada na época fica registrada; não é recalculada pela regra atual.
            taxaEntrega = v.Frete,
            tipoEntrega = delivery ? "Delivery" : "Retirada",
            plataforma = form?.Plataforma ?? v.Origem,
            pagamento = form?.Pagamento ?? RotuloPagamento(v.Pagamento?.FormaPagamento),
            status = form?.Status ?? RotuloStatus(v.Status),
            obs = form?.Observacao ?? v.Observacao ?? string.Empty,
            dataAgendada = entrega is null ? "" : entrega.DataEntrega.ToString("dd/MM/yyyy"),
            horaAgendada = entrega?.Horario ?? "",
            endereco = delivery
                ? new
                {
                    rua = entrega!.Logradouro ?? cliente?.Logradouro ?? "",
                    num = entrega.Numero ?? cliente?.Numero ?? "",
                    bairro = entrega.Bairro ?? cliente?.Bairro ?? "",
                    cid = entrega.Cidade ?? cliente?.Cidade ?? "",
                    uf = entrega.Estado ?? cliente?.Estado ?? "",
                    comp = entrega.Complemento ?? cliente?.Complemento ?? ""
                }
                : null,
            dataVenda = v.Data.ToString("dd/MM/yyyy HH:mm")
        };
    }
}
