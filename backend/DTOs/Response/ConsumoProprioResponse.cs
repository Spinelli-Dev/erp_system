// RF04 — Response DTO de Consumo Próprio
namespace MaxiMassasAPI.DTOs.Response;

/// <summary>
/// Retorno após registrar ou consultar um consumo próprio.
/// Inclui informações denormalizadas para facilitar a exibição no front-end.
/// </summary>
public class ConsumoProprioResponse
{
    public int Id { get; set; }
    public DateTime Data { get; set; }
    public int ProdutoId { get; set; }
    public string NomeProduto { get; set; } = string.Empty;
    public int Quantidade { get; set; }
    public int UsuarioId { get; set; }
    public string NomeUsuario { get; set; } = string.Empty;
    public string? Observacao { get; set; }
    /// <summary>Estoque restante após o consumo (informativo).</summary>
    public int EstoqueRestante { get; set; }
}
