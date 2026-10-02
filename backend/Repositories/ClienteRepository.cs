using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

public class ClienteRepository : Repository<Cliente>, IClienteRepository
{
    public ClienteRepository(AppDbContext context) : base(context) { }

    public async Task<IEnumerable<Cliente>> SearchByNomeAsync(string nome)
        => await _context.Clientes.AsNoTracking().Where(c => c.Nome.Contains(nome)).ToListAsync();

    public async Task<Cliente?> GetByEmailAsync(string email)
        => await _context.Clientes.AsNoTracking().FirstOrDefaultAsync(c => c.Email == email.Trim().ToLower());

    public async Task<Cliente?> GetComEnderecosAsync(int id)
        => await _context.Clientes.Include(c => c.Enderecos).FirstOrDefaultAsync(c => c.Id == id);
}