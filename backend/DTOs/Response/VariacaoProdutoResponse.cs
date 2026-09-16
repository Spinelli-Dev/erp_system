// Response DTO de VariacaoProduto — alinhado ao diagrama UML (+ Custo, MargemLucro).
namespace MaxiMassasAPI.DTOs.Response;

public class VariacaoProdutoResponse
{
    public int Id { get; set; }
    public int ProdutoId { get; set; }
    public string NomeProduto { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    /// <summary>Custo de produção (UML: Custo: decimal).</summary>
    public decimal Custo { get; set; }
    /// <summary>Margem de lucro calculada: (PrecoVenda - Custo) / PrecoVenda * 100.</summary>
    public decimal MargemLucro => PrecoVenda > 0
        ? Math.Round((PrecoVenda - Custo) / PrecoVenda * 100, 2) : 0;
}
