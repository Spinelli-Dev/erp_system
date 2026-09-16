// Registra cada entrada ou saida do estoque.
namespace MaxiMassasAPI.Models;

public class MovimentacaoEstoque
{
    public int Id { get; set; }
    public TipoMovimentacao Tipo { get; set; }
    public string Motivo { get; set; } = string.Empty;
    public int Quantidade { get; set; }
    public DateTime Data { get; set; } = DateTime.Now;
    public int EstoqueId { get; set; }
    public Estoque Estoque { get; set; } = null!;
}