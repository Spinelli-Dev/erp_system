// Entidade Pagamento — versão final alinhada ao diagrama UML.
// CAMPOS COMPLETOS: StatusPagamento, DataPagamento, CodigoTransacao, Observacao
namespace MaxiMassasAPI.Models;

public class Pagamento
{
    public int Id { get; set; }
    public FormaPagamento FormaPagamento { get; set; }

    /// <summary>Status do pagamento (UML: StatusPagamento — migrado de Venda).</summary>
    public StatusPagamento StatusPagamento { get; set; } = StatusPagamento.Pendente;

    /// <summary>Data em que o pagamento foi efetivado (UML: DataPagamento).</summary>
    public DateTime? DataPagamento { get; set; }

    /// <summary>
    /// Código de transação externo (UML: CodigoTransacao).
    /// Gerado pelo gateway de pagamento (ex: PagSeguro, Mercado Pago, Pix).
    /// </summary>
    public string? CodigoTransacao { get; set; }

    /// <summary>Observações sobre o pagamento (UML: Observacao).</summary>
    public string? Observacao { get; set; }

    public decimal Taxa { get; set; }
    public decimal ValorFinal { get; set; }

    public int VendaId { get; set; }
    public Venda Venda { get; set; } = null!;

    /// <summary>Calcula ValorFinal aplicando a taxa percentual sobre o valor da venda.</summary>
    public void Calcular(decimal valorVenda)
        => ValorFinal = valorVenda * (1 + Taxa / 100);

    /// <summary>Efetiva o pagamento com data e código de transação.</summary>
    public void Efetivar(string? codigoTransacao = null)
    {
        StatusPagamento = StatusPagamento.Pago;
        DataPagamento = DateTime.Now;
        if (!string.IsNullOrEmpty(codigoTransacao))
            CodigoTransacao = codigoTransacao;
    }
}
