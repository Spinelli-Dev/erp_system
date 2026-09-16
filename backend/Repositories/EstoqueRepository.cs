using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

public class EstoqueRepository : Repository<Estoque>, IEstoqueRepository
{
    public EstoqueRepository(AppDbContext context) : base(context) { }

    public async Task<Estoque?> GetByProdutoIdAsync(int produtoId)
        => await _context.Estoques.Include(e => e.Produto).AsNoTracking()
            .FirstOrDefaultAsync(e => e.ProdutoId == produtoId);

    public async Task<Estoque?> GetComMovimentacoesAsync(int estoqueId)
        => await _context.Estoques.Include(e => e.Produto).Include(e => e.Movimentacoes)
            .AsNoTracking().FirstOrDefaultAsync(e => e.Id == estoqueId);

    public async Task<IEnumerable<Estoque>> GetEstoquesBaixosAsync()
        => await _context.Estoques.Include(e => e.Produto).AsNoTracking()
            .Where(e => e.Quantidade <= e.AlertaMinimo).ToListAsync();
}