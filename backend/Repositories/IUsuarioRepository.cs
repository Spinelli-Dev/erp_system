using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IUsuarioRepository : IRepository<Usuario>
{
    Task<Usuario?> GetByLoginAsync(string login);
}