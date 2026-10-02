// DTO de Entrega — alinhado ao diagrama UML (DataEntrega, Taxa, ValorEntrega).
namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class EntregaRequest
{
    public TipoEntrega TipoEntrega { get; set; }
    /// <summary>Data de entrega agendada (UML: DataEntrega).</summary>
    public DateTime DataEntrega { get; set; }
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
    /// <summary>Taxa percentual de entrega (UML: Taxa). Ex: 10 = 10% do valor.</summary>
    public decimal Taxa { get; set; }
    /// <summary>Valor fixo de entrega (UML: ValorEntrega). Prioritário se > 0.</summary>
    public decimal ValorEntrega { get; set; }
}
