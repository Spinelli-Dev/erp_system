using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

public interface IUsuarioService
{
    Task<IEnumerable<UsuarioResponse>> GetAllAsync();
    Task<UsuarioResponse?> GetByIdAsync(int id);
    Task<UsuarioResponse> CreateAsync(UsuarioRequest request);

    /// <summary>Alteração pelo administrador (nome, perfil, contato, ativo, redefinir senha).</summary>
    Task<UsuarioResponse?> UpdateAsync(int id, UsuarioUpdateRequest request);

    /// <summary>Usuário com histórico (vendas, consumos) não é apagado: é desativado.</summary>
    Task<bool> DeleteAsync(int id);

    /// <summary>"Meu perfil": o próprio usuário muda nome, e-mail e telefone.</summary>
    Task<UsuarioResponse> AtualizarPerfilAsync(int id, PerfilUsuarioRequest request);

    /// <summary>Troca da própria senha: exige a senha atual.</summary>
    Task TrocarSenhaAsync(int id, string senhaAtual, string novaSenha);

    /// <summary>Grava a foto já preparada (FotoPerfilService); null remove.</summary>
    Task<UsuarioResponse> DefinirFotoAsync(int id, byte[]? foto);

    Task<(byte[] Foto, DateTime AtualizadaEm)?> ObterFotoAsync(int id);
}
