using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Repositories;

public class UsuarioRepository : Repository<Usuario>, IUsuarioRepository
{
    public UsuarioRepository(AppDbContext context) : base(context) { }

    public async Task<Usuario?> GetByLoginAsync(string login)
        => await _context.Usuarios.FirstOrDefaultAsync(u => u.Login.ToLower() == login.ToLower());
}