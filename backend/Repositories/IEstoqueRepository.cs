using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IEstoqueRepository : IRepository<Estoque>
{
    Task<Estoque?> GetByProdutoIdAsync(int produtoId);
    Task<Estoque?> GetComMovimentacoesAsync(int estoqueId);
    Task<IEnumerable<Estoque>> GetEstoquesBaixosAsync();
}