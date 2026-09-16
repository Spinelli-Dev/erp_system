using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Integrations;

namespace MaxiMassasAPI.Services;

public interface IClienteService
{
    Task<IEnumerable<ClienteResponse>> GetAllAsync();
    Task<ClienteResponse?> GetByIdAsync(int id);
    Task<ClienteResponse> CreateAsync(ClienteRequest request);
    Task<ClienteResponse?> UpdateAsync(int id, ClienteUpdateRequest request);
    Task<bool> DeleteAsync(int id);
    Task<EnderecoDto?> BuscarEnderecoPorCepAsync(string cep);
}