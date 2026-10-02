// Response DTO de Entrega — alinhado ao diagrama UML.
namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

public class EntregaResponse
{
    public int Id { get; set; }
    public TipoEntrega TipoEntrega { get; set; }
    public string TipoDescricao => TipoEntrega.ToString();
    /// <summary>Data de entrega (UML: DataEntrega).</summary>
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
    /// <summary>Taxa percentual da entrega (UML: Taxa).</summary>
    public decimal Taxa { get; set; }
    /// <summary>Valor monetário da entrega (UML: ValorEntrega).</summary>
    public decimal ValorEntrega { get; set; }
}
