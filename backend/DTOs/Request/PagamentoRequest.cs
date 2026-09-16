namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class PagamentoRequest
{
    public FormaPagamento FormaPagamento { get; set; }
    public decimal Taxa { get; set; }
    public StatusPagamento StatusPagamento { get; set; } = StatusPagamento.Pendente;
    public DateTime? DataPagamento { get; set; }
    /// <summary>Código de transação do gateway de pagamento (UML: CodigoTransacao).</summary>
    public string? CodigoTransacao { get; set; }
    /// <summary>Observações do pagamento (UML: Observacao).</summary>
    public string? Observacao { get; set; }
}
