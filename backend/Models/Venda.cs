// Entidade Venda — alinhada ao diagrama UML.
// MUDANÇAS vs versão anterior:
//   - StatusPagamento REMOVIDO daqui → movido para Pagamento (UML)
//   - StatusVenda adicionado (ciclo de vida do pedido)
//   - Frete adicionado (UML: Frete: decimal)
//   - Observacao adicionada (UML: Observacao: string)
//   - TipoDesconto e Origem mantidos (não conflitam com UML, aumentam usabilidade)
namespace MaxiMassasAPI.Models;

public class Venda
{
    public int Id { get; set; }
    public DateTime Data { get; set; } = DateTime.Now;

    // ── Desconto ─────────────────────────────────────────────────────────────
    public decimal Desconto { get; set; }
    public TipoDesconto TipoDesconto { get; set; } = TipoDesconto.Nenhum;

    // ── Frete (UML: Frete: decimal) ──────────────────────────────────────────
    public decimal Frete { get; set; } = 0;

    // ── Totais ────────────────────────────────────────────────────────────────
    public decimal ValorTotal { get; set; }

    // ── Status do PEDIDO (UML: Status: string → StatusVenda enum) ────────────
    // Separado do StatusPagamento que agora está na entidade Pagamento
    public StatusVenda Status { get; set; } = StatusVenda.Aberta;

    // ── Dados adicionais ─────────────────────────────────────────────────────
    public string? Observacao { get; set; }  // UML: Observacao: string
    public string Origem { get; set; } = "Balcao"; // Mantido: não conflita com UML

    // ── Relacionamentos ───────────────────────────────────────────────────────
    public int ClienteId { get; set; }
    public Cliente Cliente { get; set; } = null!;

    public int UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;

    public Pagamento? Pagamento { get; set; }
    public Entrega? Entrega { get; set; }
    public ICollection<ItemVenda> ItensVenda { get; set; } = new List<ItemVenda>();

    // ── Métodos do diagrama UML ───────────────────────────────────────────────

    /// <summary>
    /// Recalcula o valor total baseado nos itens, desconto e frete.
    /// UML: calcularTotal()
    /// </summary>
    public void RecalcularTotal()
    {
        var bruto = ItensVenda.Sum(i => i.Subtotal);
        var aposDesconto = TipoDesconto switch
        {
            TipoDesconto.Valor => bruto - Desconto,
            TipoDesconto.Percentual => bruto * (1 - Desconto / 100),
            _ => bruto
        };
        ValorTotal = Math.Max(0, aposDesconto) + Frete;
    }

    /// <summary>
    /// Finaliza a venda: muda status para Concluida.
    /// UML: finalizarVenda() — chamado pelo service após validações.
    /// </summary>
    public void Finalizar() => Status = StatusVenda.Concluida;

    /// <summary>Cancela a venda.</summary>
    public void Cancelar() => Status = StatusVenda.Cancelada;
}
