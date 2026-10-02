using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IClienteRepository : IRepository<Cliente>
{
    Task<IEnumerable<Cliente>> SearchByNomeAsync(string nome);
    Task<Cliente?> GetByEmailAsync(string email);
    /// <summary>Cliente com os endereços salvos, RASTREADO (para alterar e salvar).</summary>
    Task<Cliente?> GetComEnderecosAsync(int id);
}