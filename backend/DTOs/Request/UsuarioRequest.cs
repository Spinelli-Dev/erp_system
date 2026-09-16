namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class UsuarioRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Login { get; set; } = string.Empty;
    public string Senha { get; set; } = string.Empty;
    public TipoUsuario Tipo { get; set; }
}

public class UsuarioUpdateRequest
{
    public string Nome { get; set; } = string.Empty;
    public string? Senha { get; set; }
    public TipoUsuario Tipo { get; set; }
}