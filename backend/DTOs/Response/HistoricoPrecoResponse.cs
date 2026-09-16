// Response DTO de HistoricoPreco — alinhado ao diagrama UML.
namespace MaxiMassasAPI.DTOs.Response;

public class HistoricoPrecoResponse
{
    public int Id { get; set; }
    public int ProdutoId { get; set; }
    public decimal PrecoAnterior { get; set; }
    public DateTime DataAlteracao { get; set; }
    /// <summary>Motivo da alteração (UML: MotivoAlteracao).</summary>
    public string? MotivoAlteracao { get; set; }
    /// <summary>Data em que esse preço deixou de valer (UML: DataFimVigencia).</summary>
    public DateTime? DataFimVigencia { get; set; }
}
