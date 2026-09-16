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
}