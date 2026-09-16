// RF04 — DTOs de Consumo Próprio
namespace MaxiMassasAPI.DTOs.Request;

/// <summary>
/// Payload enviado pelo cliente para registrar um consumo interno de produto.
/// O usuário responsável é extraído do token de autenticação, não enviado no body.
/// </summary>
public class ConsumoProprioRequest
{
    /// <summary>ID do produto a ser consumido internamente.</summary>
    public int ProdutoId { get; set; }

    /// <summary>Quantidade a consumir. Deve ser >= 1 e <= estoque disponível.</summary>
    public int Quantidade { get; set; }

    /// <summary>Motivo ou observação do consumo (ex: "Degustação", "Uso pessoal").</summary>
    public string? Observacao { get; set; }
}
