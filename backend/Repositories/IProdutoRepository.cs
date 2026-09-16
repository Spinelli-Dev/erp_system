using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Repositories;

public interface IProdutoRepository : IRepository<Produto>
{
    Task<Produto?> GetProdutoComDetalhesAsync(int id);
    Task<IEnumerable<Produto>> GetAllComEstoqueAsync();
}