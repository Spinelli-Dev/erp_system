namespace MaxiMassasAPI.DTOs.Response;

using MaxiMassasAPI.Models;

public class ProdutoResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Sabor { get; set; }
    public string? Observacao { get; set; }
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
    public EstoqueResponse? Estoque { get; set; }
}