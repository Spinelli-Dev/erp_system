// DTOs de Produto — atualizado com MotivoAlteracao para HistoricoPreco (UML).
namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class ProdutoRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Sabor { get; set; }
    public string? Observacao { get; set; }
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
}

/// <summary>Mesmos campos (e mesmas validações) do cadastro, mais o motivo da mudança de preço.</summary>
public class ProdutoUpdateRequest : ProdutoRequest
{
    /// <summary>
    /// Motivo da alteração de preço — registrado no HistoricoPreco (UML: MotivoAlteracao).
    /// Obrigatório quando PrecoVenda é diferente do atual.
    /// </summary>
    public string? MotivoAlteracao { get; set; }
}
