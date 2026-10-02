// Response DTO de Venda — alinhado ao diagrama UML.
// MUDANÇAS: + Frete, + Observacao, Status separado de StatusPagamento
namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

public class VendaResponse
{
    public int Id { get; set; }
    public DateTime Data { get; set; }
    public decimal Desconto { get; set; }
    public TipoDesconto TipoDesconto { get; set; }
    public decimal Frete { get; set; }
    public decimal ValorTotal { get; set; }
    /// <summary>Status do pedido (UML: Status: string).</summary>
    public StatusVenda Status { get; set; }
    public string StatusDescricao => Status.ToString();
    public string? Observacao { get; set; }
    public string Origem { get; set; } = string.Empty;
    public int ClienteId { get; set; }
    public string NomeCliente { get; set; } = string.Empty;
    public int? UsuarioId { get; set; }
    public string NomeUsuario { get; set; } = string.Empty;
    public List<ItemVendaResponse> Itens { get; set; } = new();
    public PagamentoResponse? Pagamento { get; set; }
    public EntregaResponse? Entrega { get; set; }
}

public class ItemVendaResponse
{
    public int Id { get; set; }
    public int ProdutoId { get; set; }
    public string NomeProduto { get; set; } = string.Empty;
    public int Quantidade { get; set; }
    public decimal PrecoUnitario { get; set; }
    public decimal Subtotal { get; set; }
}
