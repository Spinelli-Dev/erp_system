using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IEstoqueService
{
    Task<IEnumerable<EstoqueResponse>> GetAllAsync();
    Task<EstoqueResponse?> GetByProdutoIdAsync(int produtoId);
    Task<EstoqueResponse?> GetComMovimentacoesAsync(int estoqueId);
    Task<EstoqueResponse> CreateAsync(EstoqueRequest request);
    Task<EstoqueResponse?> RegistrarMovimentacaoAsync(MovimentacaoEstoqueRequest request);
    Task<IEnumerable<EstoqueResponse>> GetEstoquesBaixosAsync();

    /// <summary>Estoque do produto; cria um zerado se ele ainda não tiver (produto cadastrado sem estoque).</summary>
    Task<EstoqueResponse> GarantirEstoqueAsync(int produtoId, int alertaMinimo = 0);

    /// <summary>Define a quantidade exata (contagem de inventário) e registra um Ajuste "de X para Y".</summary>
    Task<EstoqueResponse> AjustarQuantidadeAsync(int produtoId, int novaQuantidade, string? motivo = null);
}