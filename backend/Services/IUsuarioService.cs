using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IUsuarioService
{
    Task<IEnumerable<UsuarioResponse>> GetAllAsync();
    Task<UsuarioResponse?> GetByIdAsync(int id);
    Task<UsuarioResponse> CreateAsync(UsuarioRequest request);
    Task<UsuarioResponse?> UpdateAsync(int id, UsuarioUpdateRequest request);
    Task<bool> DeleteAsync(int id);
}