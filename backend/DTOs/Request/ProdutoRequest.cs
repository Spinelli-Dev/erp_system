// DTOs de Produto — atualizado com MotivoAlteracao para HistoricoPreco (UML).
namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class ProdutoRequest
{
    public string Nome { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
}

public class ProdutoUpdateRequest
{
    public string Nome { get; set; } = string.Empty;
    public decimal Peso { get; set; }
    public decimal PrecoVenda { get; set; }
    public decimal Custo { get; set; }
    public TipoProduto Tipo { get; set; }
    /// <summary>
    /// Motivo da alteração de preço — registrado no HistoricoPreco (UML: MotivoAlteracao).
    /// Obrigatório quando PrecoVenda é diferente do atual.
    /// </summary>
    public string? MotivoAlteracao { get; set; }
}
