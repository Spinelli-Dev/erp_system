// DTO de VariacaoProduto — alinhado ao diagrama UML (+ Custo).
namespace MaxiMassasAPI.DTOs.Request;

public class VariacaoProdutoRequest
{
    public int ProdutoId { get; set; }
    public string Descricao { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    /// <summary>Custo de produção desta variação (UML: Custo: decimal).</summary>
    public decimal Custo { get; set; }
}
