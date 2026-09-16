using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

public class ProdutoRepository : Repository<Produto>, IProdutoRepository
{
    public ProdutoRepository(AppDbContext context) : base(context) { }

    public async Task<Produto?> GetProdutoComDetalhesAsync(int id)
        => await _context.Produtos
            .Include(p => p.VariacoesProduto).Include(p => p.HistoricoPreco).Include(p => p.Estoque)
            .AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);

    public async Task<IEnumerable<Produto>> GetAllComEstoqueAsync()
        => await _context.Produtos.Include(p => p.Estoque).AsNoTracking().ToListAsync();
}