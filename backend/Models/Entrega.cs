// Entidade Entrega — alinhada ao diagrama UML.
// MUDANÇAS vs versão anterior:
//   - Data → DataEntrega (UML: DataEntrega: datetime)
//   - TaxaEntrega → Taxa (UML: Taxa: decimal)
//   - ValorEntrega adicionado (UML: ValorEntrega: decimal)
//   - TipoEntrega mantido (não conflita com UML, melhora usabilidade)
namespace MaxiMassasAPI.Models;

public class Entrega
{
    public int Id { get; set; }

    /// <summary>Tipo: Retirada no balcão ou Entrega no endereço. Mantido além do UML para operação.</summary>
    public TipoEntrega TipoEntrega { get; set; }

    /// <summary>Data agendada para a entrega (UML: DataEntrega: datetime).</summary>
    public DateTime DataEntrega { get; set; }

    /// <summary>Horário específico da entrega (ex: "14:00").</summary>
    public string Horario { get; set; } = string.Empty;

    // ── Endereço desta entrega (pode diferir do cadastro do cliente). Nulos na retirada
    //    e nas vendas de balcão, que usam o endereço do cliente. ─────────────────────
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? Cep { get; set; }
    public string? Cidade { get; set; }
    public string? Estado { get; set; }

    /// <summary>Taxa percentual de entrega (UML: Taxa: decimal). Ex: 10 = 10%.</summary>
    public decimal Taxa { get; set; }

    /// <summary>
    /// Valor monetário cobrado pela entrega (UML: ValorEntrega: decimal).
    /// Calculado pelo service: pode ser fixo ou % do pedido.
    /// </summary>
    public decimal ValorEntrega { get; set; }

    public int VendaId { get; set; }
    public Venda Venda { get; set; } = null!;

    /// <summary>
    /// Calcula o valor de entrega a partir da taxa e do valor da venda.
    /// UML: calcularTaxa()
    /// </summary>
    public void CalcularValorEntrega(decimal valorVenda)
    {
        ValorEntrega = Taxa > 0 ? valorVenda * (Taxa / 100) : ValorEntrega;
    }
}
