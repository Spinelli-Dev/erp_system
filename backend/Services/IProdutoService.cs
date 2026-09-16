using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IProdutoService
{
    Task<IEnumerable<ProdutoResponse>> GetAllAsync();
    Task<ProdutoResponse?> GetByIdAsync(int id);
    Task<ProdutoResponse> CreateAsync(ProdutoRequest request);
    Task<ProdutoResponse?> UpdateAsync(int id, ProdutoUpdateRequest request);
    Task<bool> DeleteAsync(int id);
}