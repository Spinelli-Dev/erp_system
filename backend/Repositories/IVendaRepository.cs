using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IVendaRepository : IRepository<Venda>
{
    Task<Venda?> GetVendaComDetalhesAsync(int id);
    Task<IEnumerable<Venda>> GetVendasPorPeriodoAsync(DateTime inicio, DateTime fim);
    Task<IEnumerable<Venda>> GetVendasComDetalhesAsync();
}