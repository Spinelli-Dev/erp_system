namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

public class PagamentoResponse
{
    public int Id { get; set; }
    public FormaPagamento FormaPagamento { get; set; }
    public string FormaDescricao => FormaPagamento.ToString();
    public StatusPagamento StatusPagamento { get; set; }
    public string StatusDescricao => StatusPagamento.ToString();
    public DateTime? DataPagamento { get; set; }
    /// <summary>Código do gateway de pagamento (UML: CodigoTransacao).</summary>
    public string? CodigoTransacao { get; set; }
    public string? Observacao { get; set; }
    public decimal Taxa { get; set; }
    public decimal ValorFinal { get; set; }
}
