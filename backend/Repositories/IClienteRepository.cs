using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IClienteRepository : IRepository<Cliente>
{
    Task<IEnumerable<Cliente>> SearchByNomeAsync(string nome);
}