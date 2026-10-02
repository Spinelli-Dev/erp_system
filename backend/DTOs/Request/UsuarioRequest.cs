namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

/// <summary>Cadastro de usuário do painel (feito pelo administrador).</summary>
public class UsuarioRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Login { get; set; } = string.Empty;
    public string Senha { get; set; } = string.Empty;
    public TipoUsuario Tipo { get; set; }
    public string? Email { get; set; }
    public string? Telefone { get; set; }
}

/// <summary>Alteração feita pelo administrador. Senha preenchida = redefinir; Ativo nulo = não mexer.</summary>
public class UsuarioUpdateRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Senha { get; set; }
    public TipoUsuario Tipo { get; set; }
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public bool? Ativo { get; set; }
}

/// <summary>"Meu perfil": o que o próprio usuário pode mudar nele mesmo.</summary>
public class PerfilUsuarioRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Telefone { get; set; }
}
