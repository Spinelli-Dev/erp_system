// Usuários do painel (gestores e operadores). Usado pela API (/api/Usuario) e pelas telas
// "Usuários" (administrador) e "Meu perfil" (cada um).
//
// Regras:
//   - login e e-mail únicos (antes um login repetido estourava erro do banco);
//   - senha nova segue a PoliticaSenha;
//   - o sistema nunca fica sem administrador ativo (ninguém rebaixa/desativa o último);
//   - quem tem histórico não é apagado, é desativado.
using AutoMapper;
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

public class UsuarioService : IUsuarioService
{
    private readonly IUsuarioRepository _repo;
    private readonly IMapper _mapper;
    private readonly ILogger<UsuarioService> _logger;
    private readonly AppDbContext _context;

    public UsuarioService(IUsuarioRepository repo, IMapper mapper, ILogger<UsuarioService> logger, AppDbContext context)
    { _repo = repo; _mapper = mapper; _logger = logger; _context = context; }

    public async Task<IEnumerable<UsuarioResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<UsuarioResponse>>(
            (await _context.Usuarios.AsNoTracking().OrderBy(u => u.Nome).ToListAsync()));

    public async Task<UsuarioResponse?> GetByIdAsync(int id)
    {
        var u = await _repo.GetByIdAsync(id);
        return u is null ? null : _mapper.Map<UsuarioResponse>(u);
    }

    public async Task<UsuarioResponse> CreateAsync(UsuarioRequest request)
    {
        var login = request.Login.Trim();
        var erroSenha = PoliticaSenha.Validar(request.Senha);
        if (erroSenha is not null) throw new InvalidOperationException(erroSenha);
        if (await _repo.GetByLoginAsync(login) is not null)
            throw new InvalidOperationException($"O login \"{login}\" já está em uso.");
        var email = NormalizarEmail(request.Email);
        await GarantirEmailLivreAsync(email, idAtual: null);

        var usuario = new Usuario
        {
            Nome = request.Nome.Trim(),
            Login = login,
            Senha = BCrypt.Net.BCrypt.HashPassword(request.Senha),
            Tipo = request.Tipo,
            Email = email,
            Telefone = Texto(request.Telefone),
            Ativo = true
        };
        await _repo.AddAsync(usuario);
        await _repo.SaveChangesAsync();
        _logger.LogInformation("Usuario criado: {Login} ({Tipo})", usuario.Login, usuario.Tipo);
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task<UsuarioResponse?> UpdateAsync(int id, UsuarioUpdateRequest request)
    {
        var usuario = await _repo.GetByIdAsync(id);
        if (usuario is null) return null;

        var ativo = request.Ativo ?? usuario.Ativo;
        var deixaDeSerAdminAtivo = usuario.Tipo == TipoUsuario.Administrador && usuario.Ativo
                                   && (request.Tipo != TipoUsuario.Administrador || !ativo);
        if (deixaDeSerAdminAtivo && !await ExisteOutroAdminAtivoAsync(id))
            throw new InvalidOperationException(
                "Este é o único administrador ativo: cadastre ou ative outro administrador antes de rebaixar ou desativar este.");

        if (!string.IsNullOrEmpty(request.Senha))
        {
            var erroSenha = PoliticaSenha.Validar(request.Senha);
            if (erroSenha is not null) throw new InvalidOperationException(erroSenha);
            usuario.Senha = BCrypt.Net.BCrypt.HashPassword(request.Senha);
        }

        var email = NormalizarEmail(request.Email);
        await GarantirEmailLivreAsync(email, id);

        usuario.Nome = request.Nome.Trim();
        usuario.Tipo = request.Tipo;
        usuario.Email = email;
        usuario.Telefone = Texto(request.Telefone);
        usuario.Ativo = ativo;
        await _repo.SaveChangesAsync();
        _logger.LogInformation("Usuario {Login} alterado ({Tipo}, ativo={Ativo})", usuario.Login, usuario.Tipo, usuario.Ativo);
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var u = await _repo.GetByIdAsync(id);
        if (u is null) return false;

        var temHistorico = await _context.Vendas.AnyAsync(v => v.UsuarioId == id)
                           || await _context.ConsumosProprios.AnyAsync(c => c.UsuarioId == id);
        if (temHistorico)
            throw new InvalidOperationException("Este usuário tem vendas ou consumos registrados: desative-o em vez de excluir.");
        if (u.Tipo == TipoUsuario.Administrador && u.Ativo && !await ExisteOutroAdminAtivoAsync(id))
            throw new InvalidOperationException("Não é possível excluir o único administrador ativo.");

        _repo.Remove(u);
        return await _repo.SaveChangesAsync();
    }

    public async Task<UsuarioResponse> AtualizarPerfilAsync(int id, PerfilUsuarioRequest request)
    {
        var usuario = await _repo.GetByIdAsync(id) ?? throw new KeyNotFoundException("Usuário não encontrado.");
        var email = NormalizarEmail(request.Email);
        await GarantirEmailLivreAsync(email, id);

        usuario.Nome = request.Nome.Trim();
        usuario.Email = email;
        usuario.Telefone = Texto(request.Telefone);
        await _repo.SaveChangesAsync();
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task TrocarSenhaAsync(int id, string senhaAtual, string novaSenha)
    {
        var usuario = await _repo.GetByIdAsync(id) ?? throw new KeyNotFoundException("Usuário não encontrado.");
        if (string.IsNullOrEmpty(senhaAtual) || !BCrypt.Net.BCrypt.Verify(senhaAtual, usuario.Senha))
            throw new InvalidOperationException("A senha atual não confere.");
        var erroSenha = PoliticaSenha.Validar(novaSenha);
        if (erroSenha is not null) throw new InvalidOperationException(erroSenha);
        if (BCrypt.Net.BCrypt.Verify(novaSenha, usuario.Senha))
            throw new InvalidOperationException("A nova senha deve ser diferente da atual.");

        usuario.Senha = BCrypt.Net.BCrypt.HashPassword(novaSenha);
        await _repo.SaveChangesAsync();
        _logger.LogInformation("Usuario {Login} trocou a senha.", usuario.Login);
    }

    public async Task<UsuarioResponse> DefinirFotoAsync(int id, byte[]? foto)
    {
        var usuario = await _repo.GetByIdAsync(id) ?? throw new KeyNotFoundException("Usuário não encontrado.");
        usuario.Foto = foto;
        usuario.FotoAtualizadaEm = foto is null ? null : DateTime.Now;
        await _repo.SaveChangesAsync();
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task<(byte[] Foto, DateTime AtualizadaEm)?> ObterFotoAsync(int id)
    {
        var dados = await _context.Usuarios.AsNoTracking()
            .Where(u => u.Id == id && u.Foto != null)
            .Select(u => new { u.Foto, u.FotoAtualizadaEm })
            .FirstOrDefaultAsync();
        return dados is null ? null : (dados.Foto!, dados.FotoAtualizadaEm ?? DateTime.MinValue);
    }

    // ── Auxiliares ───────────────────────────────────────────────────────────

    private Task<bool> ExisteOutroAdminAtivoAsync(int idExcluido)
        => _context.Usuarios.AnyAsync(u => u.Id != idExcluido && u.Ativo && u.Tipo == TipoUsuario.Administrador);

    private async Task GarantirEmailLivreAsync(string? email, int? idAtual)
    {
        if (email is null) return;
        if (await _context.Usuarios.AnyAsync(u => u.Email == email && u.Id != idAtual))
            throw new InvalidOperationException("Este e-mail já está em uso por outro usuário.");
    }

    private static string? NormalizarEmail(string? email) => Texto(email)?.ToLowerInvariant();

    private static string? Texto(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
