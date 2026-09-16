// Produto do catalogo da MaxiMassas.
namespace MaxiMassasAPI.Models;

public class Produto
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
    public ICollection<VariacaoProduto> VariacoesProduto { get; set; } = new List<VariacaoProduto>();
    public ICollection<HistoricoPreco> HistoricoPreco { get; set; } = new List<HistoricoPreco>();
    public Estoque? Estoque { get; set; }
}