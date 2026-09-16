// RF04 — Implementação do repositório de Consumo Próprio
using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

/// <summary>
/// Repositório concreto para ConsumoProprio.
/// Usa EF Core com Include eager loading para evitar N+1 queries.
/// </summary>
public class ConsumoProprioRepository : Repository<ConsumoProprio>, IConsumoProprioRepository
{
    public ConsumoProprioRepository(AppDbContext context) : base(context) { }

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprio>> GetAllComDetalhesAsync()
        => await _context.ConsumosProprios
            .Include(c => c.Produto)
            .Include(c => c.Usuario)
            .AsNoTracking()
            .OrderByDescending(c => c.Data)
            .ToListAsync();

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprio>> GetByPeriodoAsync(DateTime inicio, DateTime fim)
    {
        // Normaliza para início do dia (00:00) e fim do dia (23:59:59)
        var inicioDate = inicio.Date;
        var fimDate = fim.Date.AddDays(1);

        return await _context.ConsumosProprios
            .Include(c => c.Produto)
            .Include(c => c.Usuario)
            .AsNoTracking()
            .Where(c => c.Data >= inicioDate && c.Data < fimDate)
            .OrderByDescending(c => c.Data)
            .ToListAsync();
    }

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprio>> GetByProdutoIdAsync(int produtoId)
        => await _context.ConsumosProprios
            .Include(c => c.Produto)
            .Include(c => c.Usuario)
            .AsNoTracking()
            .Where(c => c.ProdutoId == produtoId)
            .OrderByDescending(c => c.Data)
            .ToListAsync();
}
