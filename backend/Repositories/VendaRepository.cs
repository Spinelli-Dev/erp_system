using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

public class VendaRepository : Repository<Venda>, IVendaRepository
{
    public VendaRepository(AppDbContext context) : base(context) { }

    public async Task<Venda?> GetVendaComDetalhesAsync(int id)
        => await _context.Vendas
            .Include(v => v.Cliente).Include(v => v.Usuario)
            .Include(v => v.ItensVenda).ThenInclude(i => i.Produto)
            .Include(v => v.Pagamento).Include(v => v.Entrega)
            .AsNoTracking().FirstOrDefaultAsync(v => v.Id == id);

    public async Task<IEnumerable<Venda>> GetVendasComDetalhesAsync()
        => await _context.Vendas
            .Include(v => v.Cliente).Include(v => v.Usuario)
            .Include(v => v.ItensVenda).ThenInclude(i => i.Produto)
            .Include(v => v.Pagamento).Include(v => v.Entrega)
            .AsNoTracking().OrderByDescending(v => v.Data).ToListAsync();

    public async Task<IEnumerable<Venda>> GetVendasPorPeriodoAsync(DateTime inicio, DateTime fim)
        => await _context.Vendas
            .Include(v => v.Cliente).Include(v => v.ItensVenda).ThenInclude(i => i.Produto)
            .Include(v => v.Pagamento).AsNoTracking()
            .Where(v => v.Data >= inicio && v.Data <= fim).OrderByDescending(v => v.Data).ToListAsync();
}