// Controla a quantidade disponivel de um produto (1:1 com Produto).
namespace MaxiMassasAPI.Models;

public class Estoque
{
    public int Id { get; set; }
    public int Quantidade { get; set; }
    public int AlertaMinimo { get; set; }
    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;
    public ICollection<MovimentacaoEstoque> Movimentacoes { get; set; } = new List<MovimentacaoEstoque>();
}