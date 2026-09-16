// Entidade VariacaoProduto — alinhada ao diagrama UML.
// MUDANÇAS vs versão anterior:
//   - Custo adicionado (UML: Custo: decimal — necessário para cálculo de lucro por variação)
namespace MaxiMassasAPI.Models;

/// <summary>
/// Variação de um produto base.
/// Exemplos (UML): tamanho, sabor, embalagem, peso.
/// Ex: "Talharim 500g", "Talharim 1kg".
/// </summary>
public class VariacaoProduto
{
    public int Id { get; set; }

    /// <summary>Descrição da variação (UML: Descricao: string). Ex: "500g - Embalagem Econômica".</summary>
    public string Descricao { get; set; } = string.Empty;

    /// <summary>Peso desta variação em kg.</summary>
    public decimal Peso { get; set; }

    /// <summary>Preço de venda da variação (pode diferir do produto base).</summary>
    public decimal PrecoVenda { get; set; }

    /// <summary>Custo de produção desta variação (UML: Custo: decimal).</summary>
    public decimal Custo { get; set; }

    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;

    /// <summary>
    /// Margem de lucro percentual desta variação.
    /// Calculado: (PrecoVenda - Custo) / PrecoVenda * 100
    /// </summary>
    public decimal MargemLucro => PrecoVenda > 0
        ? Math.Round((PrecoVenda - Custo) / PrecoVenda * 100, 2)
        : 0;
}
