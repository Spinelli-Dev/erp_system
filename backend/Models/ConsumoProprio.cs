// RF04 — Consumo Próprio
// Registra o uso interno de produtos pelos proprietários.
// NÃO gera venda nem movimentação financeira — apenas baixa de estoque.
namespace MaxiMassasAPI.Models;

public class ConsumoProprio
{
    public int Id { get; set; }

    /// <summary>Data e hora em que o consumo ocorreu.</summary>
    public DateTime Data { get; set; } = DateTime.Now;

    /// <summary>Produto consumido internamente.</summary>
    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;

    /// <summary>Quantidade consumida (deve ser > 0 e <= estoque disponível).</summary>
    public int Quantidade { get; set; }

    /// <summary>Usuário que registrou o consumo (proprietário/administrador).</summary>
    public int UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;

    /// <summary>Motivo ou observação do consumo (opcional).</summary>
    public string? Observacao { get; set; }
}
