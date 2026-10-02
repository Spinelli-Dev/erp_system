// Produto do catalogo da MaxiMassas.
namespace MaxiMassasAPI.Models;

public class Produto
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    /// <summary>Sabor (ex.: "4 Queijos"). Vazio = tradicional.</summary>
    public string? Sabor { get; set; }
    public string? Observacao { get; set; }

    /// <summary>"Pizza Calabresa" (nome + sabor) — como o produto aparece em listas, comandas e relatórios. Não é coluna.</summary>
    public string NomeCompleto => string.IsNullOrWhiteSpace(Sabor) ? Nome : $"{Nome} {Sabor}";
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
    public ICollection<VariacaoProduto> VariacoesProduto { get; set; } = new List<VariacaoProduto>();
    public ICollection<HistoricoPreco> HistoricoPreco { get; set; } = new List<HistoricoPreco>();
    public Estoque? Estoque { get; set; }
}