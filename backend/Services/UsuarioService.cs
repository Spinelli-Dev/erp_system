using AutoMapper;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;

namespace MaxiMassasAPI.Services;

public class UsuarioService : IUsuarioService
{
    private readonly IUsuarioRepository _repo;
    private readonly IMapper _mapper;
    private readonly ILogger<UsuarioService> _logger;

    public UsuarioService(IUsuarioRepository repo, IMapper mapper, ILogger<UsuarioService> logger)
    { _repo = repo; _mapper = mapper; _logger = logger; }

    public async Task<IEnumerable<UsuarioResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<UsuarioResponse>>(await _repo.GetAllAsync());

    public async Task<UsuarioResponse?> GetByIdAsync(int id)
    {
        var u = await _repo.GetByIdAsync(id);
        return u is null ? null : _mapper.Map<UsuarioResponse>(u);
    }

    public async Task<UsuarioResponse> CreateAsync(UsuarioRequest request)
    {
        var usuario = _mapper.Map<Usuario>(request);
        usuario.Senha = BCrypt.Net.BCrypt.HashPassword(request.Senha);
        await _repo.AddAsync(usuario);
        await _repo.SaveChangesAsync();
        _logger.LogInformation("Usuario criado: {Login}", usuario.Login);
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task<UsuarioResponse?> UpdateAsync(int id, UsuarioUpdateRequest request)
    {
        var usuario = await _repo.GetByIdAsync(id);
        if (usuario is null) return null;
        usuario.Nome = request.Nome;
        usuario.Tipo = request.Tipo;
        if (!string.IsNullOrWhiteSpace(request.Senha))
            usuario.Senha = BCrypt.Net.BCrypt.HashPassword(request.Senha);
        _repo.Update(usuario);
        await _repo.SaveChangesAsync();
        return _mapper.Map<UsuarioResponse>(usuario);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var u = await _repo.GetByIdAsync(id);
        if (u is null) return false;
        _repo.Remove(u);
        return await _repo.SaveChangesAsync();
    }
}