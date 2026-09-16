using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IVariacaoProdutoService
{
    Task<IEnumerable<VariacaoProdutoResponse>> GetByProdutoIdAsync(int produtoId);
    Task<VariacaoProdutoResponse> CreateAsync(VariacaoProdutoRequest request);
    Task<bool> DeleteAsync(int id);
}