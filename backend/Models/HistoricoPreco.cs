// Entidade HistoricoPreco — alinhada ao diagrama UML.
// MUDANÇAS vs versão anterior:
//   - MotivoAlteracao adicionado (UML)
//   - DataFimVigencia adicionado (UML)
namespace MaxiMassasAPI.Models;

public class HistoricoPreco
{
    public int Id { get; set; }

    /// <summary>Preço anterior antes da alteração.</summary>
    public decimal PrecoAnterior { get; set; }

    /// <summary>Data em que o preço foi alterado (início de vigência).</summary>
    public DateTime DataAlteracao { get; set; } = DateTime.Now;

    /// <summary>
    /// Motivo da alteração de preço (UML: MotivoAlteracao).
    /// Ex: "Reajuste trimestral", "Promoção", "Aumento de custo".
    /// </summary>
    public string? MotivoAlteracao { get; set; }

    /// <summary>
    /// Data em que esse preço deixou de valer (UML: DataFimVigencia).
    /// Null = preço ainda vigente.
    /// Preenchido automaticamente quando um novo preço é registrado.
    /// </summary>
    public DateTime? DataFimVigencia { get; set; }

    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;
}
