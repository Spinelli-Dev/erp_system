namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

public class UsuarioResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Login { get; set; } = string.Empty;
    public TipoUsuario Tipo { get; set; }
    public string TipoDescricao => Tipo.ToString();
}