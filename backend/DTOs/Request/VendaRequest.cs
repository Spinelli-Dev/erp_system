// DTOs de Venda — alinhados ao diagrama UML.
// MUDANÇAS: + Frete, + Observacao, StatusPagamento → agora em PagamentoRequest
namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class VendaRequest
{
    public int ClienteId { get; set; }

    /// <summary>Valor do desconto (percentual ou fixo conforme TipoDesconto).</summary>
    public decimal Desconto { get; set; }
    public TipoDesconto TipoDesconto { get; set; } = TipoDesconto.Nenhum;

    /// <summary>Valor do frete (UML: Frete: decimal).</summary>
    public decimal Frete { get; set; } = 0;

    /// <summary>Observações gerais da venda (UML: Observacao: string).</summary>
    public string? Observacao { get; set; }

    /// <summary>Canal de origem: Balcao, WhatsApp, Telefone, App.</summary>
    public string Origem { get; set; } = "Balcao";

    public List<ItemVendaRequest> Itens { get; set; } = new();
    public PagamentoRequest Pagamento { get; set; } = new();
    public EntregaRequest? Entrega { get; set; }

    /// <summary>
    /// Status inicial (opcional): Aberta (padrão), EmProcessamento ou EmEntrega ("Agendado" no painel).
    /// Ignorado quando o pagamento já vem como Pago — a venda nasce Concluida.
    /// </summary>
    public StatusVenda? Status { get; set; }
}

/// <summary>
/// Atualização de venda: permite alterar o status da venda e do pagamento separadamente.
/// UML: Status na Venda; StatusPagamento no Pagamento.
/// </summary>
public class VendaUpdateRequest
{
    /// <summary>Status do pedido (UML: Status: string → StatusVenda).</summary>
    public StatusVenda Status { get; set; } = StatusVenda.Aberta;

    /// <summary>Status do pagamento (UML: Pagamento.StatusPagamento).</summary>
    public StatusPagamento StatusPagamento { get; set; } = StatusPagamento.Pendente;

    /// <summary>Marca a data do pagamento quando StatusPagamento = Pago.</summary>
    public DateTime? DataPagamento { get; set; }

    public string Origem { get; set; } = string.Empty;

    /// <summary>Troca a forma de pagamento (opcional; nulo mantém a atual).</summary>
    public FormaPagamento? FormaPagamento { get; set; }

    /// <summary>Troca a observação da venda (opcional; nulo mantém a atual).</summary>
    public string? Observacao { get; set; }
}
